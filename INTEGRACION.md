# Documentación de Integración Frontend-Backend

## Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto `dicri-backend` con las siguientes variables:

```env
# Configuración de Base de Datos SQL Server
DB_SERVER=localhost
DB_NAME=DICRI
DB_USER=sa
DB_PASSWORD=YourPassword
DB_PORT=1433
DB_ENCRYPT=true

# Si tu instancia de SQL Server no es la predeterminada, usa:
# DB_SERVER=localhost\SQLEXPRESS
# o
# DB_SERVER=localhost\TU_INSTANCIA

# Clave secreta para firmar y verificar tokens JWT
# IMPORTANTE: Usa una clave segura en producción (mínimo 32 caracteres aleatorios)
JWT_SECRET=tu_clave_secreta_jwt_muy_segura_aqui_minimo_32_caracteres

# Puerto en el que corre el servidor Express
PORT=3000
```

### Nota sobre la conexión a la base de datos

El servidor puede iniciar **incluso si la base de datos no está disponible**. Esto permite:
- Acceder a Swagger UI para ver la documentación
- Probar endpoints que no requieren BD (como `/health`)
- Desarrollar el frontend mientras se configura la BD

Los endpoints que requieren base de datos fallarán con un error apropiado si la conexión no está disponible.

**Si tienes problemas de conexión a la BD, consulta [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

## Instalación de Dependencias

El backend requiere las siguientes dependencias que deben estar en `package.json`:

```bash
npm install express cors helmet morgan jsonwebtoken dotenv mssql
```

O usando pnpm:

```bash
pnpm add express cors helmet morgan jsonwebtoken dotenv mssql
```

## Acceso a Swagger UI

Una vez que el servidor esté corriendo, puedes acceder a la documentación interactiva de la API en:

**URL**: `http://localhost:3000/api-docs`

### Pasos para usar Swagger:

1. **Iniciar el servidor backend**:
   ```bash
   cd dicri-backend
   pnpm dev
   # o
   npm run dev
   ```

2. **Abrir en el navegador**: `http://localhost:3000/api-docs`

3. **Autenticarse**:
   - Primero, usa el endpoint `/api/auth/login` para obtener un token JWT
   - Copia el token de la respuesta
   - Haz clic en el botón **"Authorize"** (🔒) en la parte superior de Swagger
   - Pega el token en el campo (sin la palabra "Bearer", solo el token)
   - Haz clic en **"Authorize"** y luego en **"Close"**

4. **Probar endpoints**: Ahora puedes probar todos los endpoints protegidos directamente desde Swagger

## Endpoints Implementados

### Autenticación

- **POST /api/auth/login**
  - Body: `{ "username": "string", "password": "string" }`
  - Response: `{ "token": "jwt_token_string", "user": { "id": number, "nombre": "string", "rol": "Tecnico" | "Coordinador" } }`

### Expedientes

- **POST /api/expedientes** (Requiere autenticación, rol: Tecnico)
  - Body: `{ "datosGenerales": "string", "tecnicoId": number }`
  - Response: `{ "expedienteId": number, "message": "Expediente registrado con éxito." }`

- **GET /api/expedientes** (Requiere autenticación)
  - Query params: `?estado=APROBADO` (opcional)
  - Response: Array de expedientes

- **PUT /api/expedientes/:id/review** (Requiere autenticación, rol: Coordinador)
  - Body: `{ "status": "APROBADO" | "RECHAZADO", "justificacion": "string" }`
  - Response: `{ "expedienteId": number, "status": "APROBADO" | "RECHAZADO", "message": "Expediente revisado exitosamente." }`

### Indicios

- **POST /api/indicios** (Requiere autenticación, rol: Tecnico)
  - Body: `{ "expedienteId": number, "descripcion": "string", "color": "string", "tamano": "string", "peso": number, "ubicacion": "string", "tecnicoId": number }`
  - Response: `{ "indicioId": number, "message": "Indicio registrado con éxito." }`

- **GET /api/indicios/:expedienteId** (Requiere autenticación)
  - Response: Array de indicios

### Reportes

- **GET /api/reports** (Requiere autenticación)
  - Query params: `?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&status=APROBADO`
  - Response: Array de objetos con información de expedientes

## Manejo de Errores

Todos los errores siguen el formato estandarizado:

```json
{
  "error": "Tipo de error",
  "details": "Descripción detallada del error"
}
```

### Códigos HTTP

- **200/201**: Éxito
- **400**: Validación fallida
- **401**: No autorizado (token inválido o ausente)
- **403**: Acceso denegado (rol insuficiente)
- **404**: Recurso no encontrado
- **500**: Error interno del servidor

## Headers Requeridos

Para todas las peticiones protegidas (excepto `/api/auth/login`):

```
Authorization: Bearer [JWT_token]
Content-Type: application/json
```

