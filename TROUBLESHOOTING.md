# Guía de Solución de Problemas - Conexión a Base de Datos

## Error: Failed to connect to localhost:1433

Este error indica que el servidor no puede conectarse a SQL Server. Sigue estos pasos para solucionarlo:

### 1. Verificar que SQL Server esté corriendo

**Windows:**
- Abre **SQL Server Configuration Manager**
- Verifica que el servicio **SQL Server (MSSQLSERVER)** o tu instancia esté **Running**
- Si no está corriendo, haz clic derecho → **Start**

**Alternativa:**
```powershell
# Verificar servicios de SQL Server
Get-Service | Where-Object {$_.DisplayName -like "*SQL*"}
```

### 2. Verificar que TCP/IP esté habilitado

1. Abre **SQL Server Configuration Manager**
2. Expande **SQL Server Network Configuration**
3. Selecciona **Protocols for MSSQLSERVER** (o tu instancia)
4. Verifica que **TCP/IP** esté **Enabled**
5. Si no está habilitado, haz clic derecho → **Enable**
6. **Reinicia el servicio SQL Server** después de habilitar TCP/IP

### 3. Verificar el puerto

Por defecto, SQL Server usa el puerto **1433**. Verifica:

1. En **SQL Server Configuration Manager** → **Protocols for MSSQLSERVER** → **TCP/IP**
2. Haz doble clic en **TCP/IP**
3. Ve a la pestaña **IP Addresses**
4. Busca **IPAll** y verifica el **TCP Port** (debe ser 1433 o el que configuraste)

### 4. Verificar el archivo .env

Asegúrate de que tu archivo `.env` tenga las siguientes variables:

```env
DB_SERVER=localhost
DB_NAME=DICRI
DB_USER=sa
DB_PASSWORD=TuPassword
DB_PORT=1433
DB_ENCRYPT=true
```

**Nota:** Si tu instancia de SQL Server no es la predeterminada, usa:
```env
DB_SERVER=localhost\SQLEXPRESS
# o
DB_SERVER=localhost\TU_INSTANCIA
```

### 5. Verificar autenticación de SQL Server

1. Abre **SQL Server Management Studio (SSMS)**
2. Conecta al servidor
3. Haz clic derecho en el servidor → **Properties** → **Security**
4. Verifica que **SQL Server and Windows Authentication mode** esté seleccionado
5. Si cambias esto, **reinicia SQL Server**

### 6. Verificar firewall

Asegúrate de que el puerto 1433 esté abierto en el firewall de Windows:

```powershell
# Verificar reglas de firewall
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*SQL*"}

# Si no hay reglas, crear una (ejecutar como administrador)
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

### 7. Probar conexión manualmente

Puedes probar la conexión usando `sqlcmd`:

```powershell
sqlcmd -S localhost -U sa -P TuPassword -Q "SELECT @@VERSION"
```

O usando Node.js:

```javascript
const sql = require('mssql');

const config = {
  user: 'sa',
  password: 'TuPassword',
  server: 'localhost',
  database: 'DICRI',
  options: {
    encrypt: true,
    trustServerCertificate: true
  }
};

sql.connect(config)
  .then(() => console.log('Connected!'))
  .catch(err => console.error('Error:', err));
```

### 8. Verificar que la base de datos existe

Asegúrate de que la base de datos `DICRI` existe:

```sql
-- En SSMS o sqlcmd
SELECT name FROM sys.databases WHERE name = 'DICRI';
```

Si no existe, créala:

```sql
CREATE DATABASE DICRI;
```

### 9. Modo de desarrollo sin base de datos

Si solo necesitas probar Swagger y no tienes SQL Server disponible, el servidor ahora puede iniciar sin conexión a la base de datos. Los endpoints que requieren BD fallarán, pero Swagger estará disponible.

### 10. Logs adicionales

Si el problema persiste, verifica los logs de SQL Server:

**Ubicación de logs:**
- `C:\Program Files\Microsoft SQL Server\[VERSION]\MSSQL\Log\ERRORLOG`

O usa:

```sql
EXEC xp_readerrorlog;
```

## Errores comunes y soluciones

### Error: "Login failed for user"
- **Solución:** Verifica que el usuario y contraseña sean correctos
- Verifica que SQL Server Authentication esté habilitado

### Error: "Cannot connect to [instancia]"
- **Solución:** Verifica que el nombre del servidor sea correcto
- Si es una instancia nombrada, usa: `localhost\NOMBRE_INSTANCIA`

### Error: "Connection timeout"
- **Solución:** Aumenta el `connectionTimeout` en la configuración
- Verifica que el firewall no esté bloqueando el puerto

### Error: "Database 'DICRI' does not exist"
- **Solución:** Crea la base de datos o cambia `DB_NAME` en el `.env`

## Contacto

Si después de seguir estos pasos el problema persiste, verifica:
1. Versión de SQL Server instalada
2. Versión de Node.js y mssql package
3. Logs del servidor para más detalles del error

