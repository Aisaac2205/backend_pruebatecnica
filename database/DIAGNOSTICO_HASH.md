# Diagnóstico de Problema de Hash de Contraseña

## Problema Identificado
El stored procedure `dicri.sp_Auth_Login` se ejecuta correctamente pero devuelve `recordsetLength: 0`, indicando que la combinación de EmailLogin y PasswordHash no coincide.

## Verificaciones Realizadas

### ✅ 1. Consistencia del Algoritmo de Hashing

**Archivo: `02_procedures.sql` (SP de Login)**
```sql
SET @passwordHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', @password), 2);
```

**Archivo: `03_insert_users_manual.sql` (Inserción de Usuarios)**
```sql
CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2)
```

**Resultado:** ✅ Ambos scripts usan **SHA2_256** con el mismo formato `CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', ...), 2)`

### ✅ 2. Parámetros del Stored Procedure

**SP espera:**
- `@emailLogin NVARCHAR(50)`
- `@password NVARCHAR(255)`

**authRepository.ts envía:**
- `emailLogin` (sin @, correcto para mssql)
- `password` (sin @, correcto para mssql)

**Resultado:** ✅ Los parámetros coinciden correctamente

### ✅ 3. Estructura de la Tabla

**Columnas esperadas:**
- `UsuarioID` (PK)
- `EmailLogin` (UNIQUE)
- `PasswordHash`
- `Rol`
- `NombreCompleto`

**SP selecciona:**
- `UsuarioID, EmailLogin, Rol, NombreCompleto`

**Resultado:** ✅ La estructura coincide

## Pasos de Diagnóstico

### Paso 1: Ejecutar Script de Diagnóstico

Ejecuta el archivo `04_diagnostico_hash.sql` en SQL Server Management Studio o tu cliente SQL preferido. Este script:

1. Verifica la estructura de la tabla
2. Muestra los usuarios existentes
3. Compara el hash almacenado vs el hash generado
4. Ejecuta el SP manualmente
5. Verifica los parámetros del SP

### Paso 2: Verificar Hash Manualmente

Ejecuta estos comandos en SQL Server:

```sql
-- 1. Ver el hash almacenado
SELECT 
    EmailLogin,
    PasswordHash,
    LEN(PasswordHash) as HashLength
FROM dicri.Usuarios
WHERE EmailLogin = 'tecnico.01@mp.gt';

-- 2. Generar el hash de la contraseña de prueba
SELECT CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2) as GeneratedHash;

-- 3. Comparar ambos (deben ser IDÉNTICOS)
DECLARE @storedHash NVARCHAR(255);
DECLARE @generatedHash NVARCHAR(255);

SELECT @storedHash = PasswordHash 
FROM dicri.Usuarios 
WHERE EmailLogin = 'tecnico.01@mp.gt';

SET @generatedHash = CONVERT(NVARCHAR(255), HASHBYTES('SHA2_256', 'DicriPass#2025'), 2);

SELECT 
    @storedHash as StoredHash,
    @generatedHash as GeneratedHash,
    CASE 
        WHEN @storedHash = @generatedHash THEN '✓ COINCIDEN'
        ELSE '✗ NO COINCIDEN'
    END as Comparacion;
```

### Paso 3: Verificar Contraseña desde Frontend

**Problema Potencial:** La contraseña puede tener caracteres especiales mal codificados o espacios adicionales.

**Solución:** 
1. Revisa los logs del backend cuando se intenta hacer login
2. El repositorio ahora muestra la contraseña completa en los logs (solo para diagnóstico)
3. Verifica que la contraseña sea exactamente: `DicriPass#2025` (sin espacios, mayúsculas/minúsculas correctas)

### Paso 4: Ejecutar SP Manualmente

```sql
EXEC dicri.sp_Auth_Login 
    @emailLogin = 'tecnico.01@mp.gt', 
    @password = 'DicriPass#2025';
```

**Si devuelve 1 fila:** El problema está en Node.js o en cómo se envían los parámetros
**Si devuelve 0 filas:** El hash almacenado es incorrecto, ejecutar `03_insert_users_manual.sql` de nuevo

## Soluciones Posibles

### Solución 1: Reinsertar Usuarios

Si los hashes no coinciden, ejecuta:

```sql
-- Limpiar usuarios existentes
DELETE FROM dicri.Usuarios WHERE EmailLogin IN ('tecnico.01@mp.gt', 'coordinador.01@mp.gt');

-- Reinsertar con el script correcto
-- Ejecutar: 03_insert_users_manual.sql
```

### Solución 2: Verificar Codificación de Caracteres

El carácter `#` puede causar problemas si hay codificación incorrecta. Verifica:

1. Que el frontend envíe la contraseña como string UTF-8
2. Que Node.js no modifique la contraseña antes de enviarla al SP
3. Que SQL Server reciba la contraseña correctamente

### Solución 3: Verificar Logs del Backend

Revisa los logs cuando intentas hacer login. Deberías ver:

```
[authRepository] loginUser - Parámetros enviados: {
  emailLogin: 'tecnico.01@mp.gt',
  passwordLength: 14,
  passwordFull: 'DicriPass#2025',  // Debe ser exactamente esto
  passwordCharCodes: '68,105,99,114,105,80,97,115,115,35,50,48,50,53'
}
```

Los códigos de caracteres para `DicriPass#2025` deben ser:
- D=68, i=105, c=99, r=114, i=105, P=80, a=97, s=115, s=115, #=35, 2=50, 0=48, 2=50, 5=53

## Checklist Final

- [ ] Ejecutar `04_diagnostico_hash.sql` y revisar resultados
- [ ] Verificar que el hash almacenado = hash generado
- [ ] Verificar que la contraseña desde el frontend sea exactamente `DicriPass#2025`
- [ ] Ejecutar el SP manualmente y verificar que devuelve resultados
- [ ] Revisar logs del backend para ver qué contraseña se está enviando
- [ ] Si los hashes no coinciden, reinsertar usuarios con `03_insert_users_manual.sql`

## Notas Importantes

1. **El hash debe ser exactamente igual:** Cualquier diferencia (espacios, mayúsculas/minúsculas, codificación) hará que no coincidan
2. **SHA2_256 es el algoritmo correcto:** No usar SHA1
3. **El formato CONVERT(..., 2) es crítico:** El parámetro `2` asegura la conversión hexadecimal sin el prefijo `0x`
4. **Los parámetros del SP deben coincidir exactamente:** `@emailLogin` y `@password` (sin @ en Node.js)

