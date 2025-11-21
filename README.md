# DICRI Backend - API RESTful

Backend del Sistema de Gestión de Evidencia Criminalística desarrollado con Node.js, Express y TypeScript.

## Descripción del Proyecto

DICRI Backend es una API RESTful diseñada para gestionar expedientes e indicios en el contexto criminalístico. El sistema permite a técnicos crear y gestionar expedientes con sus respectivos indicios, mientras que los coordinadores pueden revisar y aprobar estos expedientes.

### Propósito

El backend proporciona una capa de servicios que abstrae la complejidad del acceso a datos mediante el patrón Repository, delegando toda la lógica de negocio crítica a Stored Procedures de SQL Server. Esta arquitectura garantiza:

- Seguridad: Prevención de SQL Injection mediante parámetros tipados
- Integridad: Reglas de negocio centralizadas en la base de datos
- Performance: Optimización de consultas en el servidor de BD
- Mantenibilidad: Lógica de negocio centralizada y fácil de auditar

### Características Principales

- Autenticación JWT: Sistema de tokens seguros para autenticación sin estado
- Autorización por Roles: Control de acceso basado en roles (Técnico/Coordinador)
- Repository Pattern: Abstracción completa del acceso a datos
- Stored Procedures: Toda la lógica de negocio encapsulada en SQL Server
- Documentación Swagger: Documentación interactiva de la API disponible en `/api-docs`
- Seguridad: Implementación de Helmet, CORS configurado, validación de entrada
- Testing: Suite de tests con Jest y Supertest para endpoints críticos

## Tecnologías Usadas

### Runtime y Framework

- **Node.js 18+**: Entorno de ejecución JavaScript del lado del servidor
- **Express**: Framework web minimalista y flexible para Node.js que facilita la creación de APIs RESTful

### Lenguaje y Tipado

- **TypeScript**: Superset de JavaScript que añade tipado estático, mejorando la detección temprana de errores y facilitando el mantenimiento del código

### Base de Datos

- **SQL Server**: Sistema de gestión de bases de datos relacionales de Microsoft
- **mssql**: Driver nativo para Node.js que permite ejecutar Stored Procedures con control total sobre parámetros de entrada y salida

### Autenticación y Seguridad

- **jsonwebtoken**: Librería para generar y verificar tokens JWT
- **helmet**: Middleware que establece varios headers HTTP de seguridad
- **cors**: Middleware para habilitar Cross-Origin Resource Sharing de forma controlada

### Utilidades y Herramientas

- **dotenv**: Carga variables de entorno desde archivo `.env`
- **morgan**: Middleware de logging HTTP para registrar requests
- **swagger-ui-express**: Interfaz web para documentación interactiva de la API

### Testing

- **Jest**: Framework de testing con soporte para mocks y assertions
- **Supertest**: Librería para testing de endpoints HTTP sin necesidad de levantar el servidor

## Instalación y Configuración

### Requisitos Previos

- Node.js 18 o superior
- npm o pnpm como gestor de paquetes
- SQL Server (local o remoto) con acceso configurado
- Acceso a la base de datos para ejecutar scripts SQL

### 1. Clonar el Repositorio

Si el proyecto está en un repositorio Git:

```bash
git clone <url-del-repositorio>
cd PruebaTecnica/dicri-backend
```

### 2. Instalación de Dependencias

Instalar todas las dependencias del proyecto:

```bash
npm install
```

O si prefieres usar pnpm:

```bash
pnpm install
```

### 3. Configuración de Variables de Entorno

Crear un archivo `.env` en la raíz del directorio `dicri-backend/` con el siguiente contenido:

```env
# Configuración de Base de Datos
DB_SERVER=tu-servidor-sql.database.windows.net
DB_NAME=DB_DICRI
DB_USER=tu-usuario
DB_PASSWORD=tu-contraseña
DB_PORT=1433
DB_ENCRYPT=true

# Configuración JWT
JWT_SECRET=tu-secret-key-super-segura-aqui-minimo-32-caracteres

# Configuración del Servidor
PORT=3000
NODE_ENV=development
```

**Nota importante**: El nombre de la variable de entorno para la base de datos es `DB_NAME` en el código (ver `src/config/db.ts`). Si usas Docker Compose, puede que se use `DB_DATABASE` en el archivo `docker-compose.yml`. Ajusta según tu configuración.

### 4. Configuración de Base de Datos

Ejecutar los scripts SQL en el siguiente orden estricto:

1. **01_tables.sql**: Crea el esquema `dicri` y todas las tablas necesarias
   ```sql
   -- Ejecutar en SQL Server Management Studio o herramienta similar
   ```

2. **02_procedures.sql**: Crea todos los Stored Procedures que contienen la lógica de negocio

3. **03_insert_users.sql**: Inserta usuarios de prueba para desarrollo
   - Usuario técnico: `tecnico.01@mp.gt` / `DicriPass#2025`
   - Usuario coordinador: `coordinador.01@mp.gt` / `DicriPass#2025`

4. **11_insert_tipos_expediente.sql**: Inserta los tipos de expediente en el catálogo

**Scripts de Diagnóstico (Opcional)**: Si hay problemas con autenticación o hashes de contraseñas, ejecutar los scripts desde `04_diagnostico_hash.sql` hasta `12_actualizar_hash_coordinador.sql`.

### 5. Compilar TypeScript

Compilar el código TypeScript a JavaScript:

```bash
npm run build
```

Esto generará los archivos compilados en la carpeta `dist/`.

### 6. Ejecutar el Servidor

#### Modo Producción

```bash
npm start
```

El servidor iniciará usando los archivos compilados de la carpeta `dist/` y estará disponible en `http://localhost:3000` (o el puerto configurado en `.env`).

#### Modo Desarrollo

Para desarrollo con hot-reload automático:

```bash
npm run dev
```

Este comando utiliza `ts-node-dev` para compilar y recargar automáticamente cuando detecta cambios en los archivos fuente.

### Verificación

Una vez iniciado el servidor, verificar que esté funcionando:

- Health Check: `http://localhost:3000/health` - Debe retornar `{"status":"ok"}`
- Swagger UI: `http://localhost:3000/api-docs` - Documentación interactiva de la API

## Endpoints de la API

### Autenticación

#### POST /api/auth/login

Inicia sesión y obtiene un token JWT para autenticación.

**Autenticación requerida**: No

**Request Body:**
```json
{
  "email": "tecnico.01@mp.gt",
  "password": "DicriPass#2025"
}
```

**Response 200 OK:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "tecnico.01@mp.gt",
    "rol": "Tecnico",
    "nombre": "Técnico 01"
  }
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Validación fallida",
  "details": "El email y la contraseña son requeridos."
}
```

**Response 401 Unauthorized:**
```json
{
  "error": "Credenciales inválidas",
  "details": "El email o la contraseña son incorrectos."
}
```

### Expedientes

#### GET /api/expedientes

Lista todos los expedientes. Puede filtrarse por estado mediante query parameter.

**Autenticación requerida**: Sí (Bearer Token)

**Query Parameters:**
- `estado` (opcional): Filtra por estado del expediente (BORRADOR, EN_REVISION, APROBADO, RECHAZADO)

**Headers:**
```
Authorization: Bearer <token>
```

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "codigo": "EXP-2025-001",
    "datosGenerales": "Información del caso...",
    "estado": "EN_REVISION",
    "fecha": "2025-01-15T10:30:00.000Z",
    "tecnico": "Técnico 01",
    "tipoExpediente": "Homicidio"
  }
]
```

#### GET /api/expedientes/:id

Obtiene un expediente específico por su ID.

**Autenticación requerida**: Sí (Bearer Token)

**Path Parameters:**
- `id`: ID numérico del expediente

**Response 200 OK:**
```json
{
  "id": 1,
  "codigo": "EXP-2025-001",
  "datosGenerales": "Información detallada del caso...",
  "estado": "EN_REVISION",
  "fecha": "2025-01-15T10:30:00.000Z",
  "tecnico": "Técnico 01",
  "tipoExpediente": "Homicidio"
}
```

**Response 404 Not Found:**
```json
{
  "error": "Recurso no encontrado",
  "details": "El expediente ID 1 no existe o tiene un técnico inválido."
}
```

#### POST /api/expedientes

Crea un nuevo expediente.

**Autenticación requerida**: Sí (Bearer Token)
**Rol requerido**: Técnico

**Request Body:**
```json
{
  "datosGenerales": "Descripción detallada del caso criminalístico",
  "tipoExpedienteId": 1
}
```

**Nota**: El `tecnicoId` se obtiene automáticamente del token JWT. Si se proporciona en el body, se usa ese valor.

**Response 201 Created:**
```json
{
  "expedienteId": 1,
  "message": "Expediente registrado con éxito."
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Validación fallida",
  "details": "El campo datosGenerales es requerido."
}
```

#### PUT /api/expedientes/:id/review

Revisa y aprueba o rechaza un expediente. Solo disponible para coordinadores.

**Autenticación requerida**: Sí (Bearer Token)
**Rol requerido**: Coordinador

**Path Parameters:**
- `id`: ID numérico del expediente

**Request Body:**
```json
{
  "status": "APROBADO",
  "justificacion": null
}
```

O para rechazar:

```json
{
  "status": "RECHAZADO",
  "justificacion": "Falta documentación adicional requerida"
}
```

**Response 200 OK:**
```json
{
  "expedienteId": 1,
  "status": "APROBADO",
  "message": "Expediente revisado exitosamente."
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Validación fallida",
  "details": "La justificación es obligatoria para el rechazo."
}
```

#### DELETE /api/expedientes/:id

Elimina un expediente. Los técnicos solo pueden eliminar sus propios expedientes.

**Autenticación requerida**: Sí (Bearer Token)
**Rol requerido**: Técnico (propios) o Coordinador

**Path Parameters:**
- `id`: ID numérico del expediente

**Response 200 OK:**
```json
{
  "message": "Expediente eliminado exitosamente."
}
```

**Response 403 Forbidden:**
```json
{
  "error": "Acceso Denegado",
  "details": "No tiene permisos para eliminar este expediente."
}
```

### Indicios

#### GET /api/indicios/:expedienteId

Lista todos los indicios asociados a un expediente.

**Autenticación requerida**: Sí (Bearer Token)

**Path Parameters:**
- `expedienteId`: ID numérico del expediente

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "descripcion": "Arma de fuego encontrada en la escena",
    "color": "Negro",
    "tamano": "15cm x 8cm",
    "peso": "0.5",
    "ubicacion": "Sala de evidencias - Estante A-3",
    "fechaRegistro": "2025-01-15T11:00:00.000Z"
  }
]
```

#### POST /api/indicios

Crea un nuevo indicio asociado a un expediente.

**Autenticación requerida**: Sí (Bearer Token)
**Rol requerido**: Técnico

**Request Body:**
```json
{
  "expedienteId": 1,
  "descripcion": "Arma de fuego encontrada en la escena del crimen",
  "color": "Negro",
  "tamano": "15cm x 8cm",
  "peso": "0.5",
  "ubicacion": "Sala de evidencias - Estante A-3"
}
```

**Campos obligatorios**: `expedienteId`, `descripcion`, `ubicacion`
**Campos opcionales**: `color`, `tamano`, `peso`

**Response 201 Created:**
```json
{
  "indicioId": 1,
  "message": "Indicio registrado con éxito."
}
```

### Catálogos

#### GET /api/catalogos/tipo-expediente

Obtiene la lista de tipos de expediente disponibles.

**Autenticación requerida**: No

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "nombre": "Homicidio",
    "activo": true
  },
  {
    "id": 2,
    "nombre": "Robo",
    "activo": true
  }
]
```

### Reportes

#### GET /api/reports

Genera un reporte de expedientes e indicios con filtros opcionales.

**Autenticación requerida**: Sí (Bearer Token)

**Query Parameters:**
- `start_date` (opcional): Fecha de inicio en formato YYYY-MM-DD
- `end_date` (opcional): Fecha de fin en formato YYYY-MM-DD
- `status` (opcional): Estado del expediente para filtrar

**Ejemplo:**
```
GET /api/reports?start_date=2025-01-01&end_date=2025-01-31&status=APROBADO
```

**Response 200 OK:**
```json
[
  {
    "expedienteId": 1,
    "codigo": "EXP-2025-001",
    "fechaRegistro": "2025-01-15",
    "estado": "APROBADO",
    "tecnicoNombre": "Técnico 01",
    "totalIndicios": 3
  }
]
```

### Otros Endpoints

#### GET /health

Health check del servidor. Útil para monitoreo y verificación de disponibilidad.

**Response 200 OK:**
```json
{
  "status": "ok"
}
```

#### GET /api-docs

Interfaz web de Swagger UI para documentación interactiva de la API. Permite probar endpoints directamente desde el navegador.

## Ejemplos de Uso

### Ejemplo 1: Autenticación y Obtención de Token

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "tecnico.01@mp.gt",
    "password": "DicriPass#2025"
  }'
```

**Respuesta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "tecnico.01@mp.gt",
    "rol": "Tecnico",
    "nombre": "Técnico 01"
  }
}
```

### Ejemplo 2: Crear un Expediente

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:3000/api/expedientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "datosGenerales": "Caso de homicidio ocurrido el 15 de enero de 2025 en la zona 10",
    "tipoExpedienteId": 1
  }'
```

**Respuesta:**
```json
{
  "expedienteId": 1,
  "message": "Expediente registrado con éxito."
}
```

### Ejemplo 3: Listar Expedientes

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://localhost:3000/api/expedientes \
  -H "Authorization: Bearer $TOKEN"
```

### Ejemplo 4: Agregar un Indicio a un Expediente

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:3000/api/indicios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "expedienteId": 1,
    "descripcion": "Arma de fuego calibre 9mm",
    "color": "Negro",
    "tamano": "15cm x 8cm",
    "peso": "0.5",
    "ubicacion": "Sala de evidencias - Estante A-3"
  }'
```

### Ejemplo 5: Revisar y Aprobar un Expediente (Coordinador)

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Token de coordinador

curl -X PUT http://localhost:3000/api/expedientes/1/review \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "APROBADO",
    "justificacion": null
  }'
```

### Ejemplo 6: Generar Reporte con Filtros

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET "http://localhost:3000/api/reports?start_date=2025-01-01&end_date=2025-01-31&status=APROBADO" \
  -H "Authorization: Bearer $TOKEN"
```

## Arquitectura

### Estructura de Carpetas

```
dicri-backend/
├── src/
│   ├── app.ts                 # Configuración de Express y middlewares
│   ├── server.ts             # Punto de entrada del servidor
│   ├── config/
│   │   └── db.ts             # Configuración de conexión SQL Server
│   ├── controllers/          # Controladores de rutas (manejo HTTP)
│   │   ├── authController.ts
│   │   ├── expedienteController.ts
│   │   ├── indicioController.ts
│   │   ├── catalogoController.ts
│   │   └── reportController.ts
│   ├── services/             # Lógica de negocio (orquestación)
│   │   ├── authService.ts
│   │   ├── expedienteService.ts
│   │   ├── indicioService.ts
│   │   ├── catalogoService.ts
│   │   └── reportService.ts
│   ├── db/                   # Repositorios (Repository Pattern)
│   │   ├── authRepository.ts
│   │   ├── expedienteRepository.ts
│   │   ├── indicioRepository.ts
│   │   ├── catalogoRepository.ts
│   │   └── reportRepository.ts
│   ├── routes/               # Definición de rutas
│   │   ├── authRoutes.ts
│   │   ├── expedienteRoutes.ts
│   │   ├── indicioRoutes.ts
│   │   ├── catalogoRoutes.ts
│   │   └── reportRoutes.ts
│   ├── middlewares/          # Middlewares personalizados
│   │   └── authMiddleware.ts # Autenticación y autorización
│   ├── types/                 # Definiciones TypeScript
│   │   └── index.ts
│   └── utils/                # Utilidades
├── database/                 # Scripts SQL
│   ├── 01_tables.sql         # Esquema y tablas
│   ├── 02_procedures.sql     # Stored Procedures
│   └── 03_insert_users.sql  # Datos iniciales
├── tests/                     # Tests unitarios
│   ├── setup.ts
│   ├── authController.test.ts
│   ├── authService.test.ts
│   └── expedienteController.test.ts
├── dist/                     # Código compilado (TypeScript → JavaScript)
├── Dockerfile                # Configuración Docker
├── package.json
├── tsconfig.json
└── jest.config.js
```

### Flujo de Request

```
Cliente HTTP Request
    ↓
Routes (ruta específica)
    ↓
Middleware (authMiddleware, roleMiddleware)
    ↓
Controller (valida entrada, maneja HTTP)
    ↓
Service (orquestación, validaciones de negocio)
    ↓
Repository (abstracción de datos)
    ↓
Stored Procedure (lógica de negocio en SQL)
    ↓
SQL Server Database
    ↓
Response (JSON)
```

### Repository Pattern

El patrón Repository abstrae completamente el acceso a datos. Los controladores y servicios no conocen los detalles de implementación de la base de datos, solo interactúan con métodos del repositorio.

**Ejemplo:**
```typescript
// Repository
export const createExpediente = async (
  datosGenerales: string, 
  tecnicoId: number, 
  tipoExpedienteId: number
) => {
  const pool = await getConnection();
  const result = await pool.request()
    .input('datosGenerales', sql.NVarChar, datosGenerales)
    .input('tecnicoId', sql.Int, tecnicoId)
    .input('tipoExpedienteId', sql.Int, tipoExpedienteId)
    .execute('dicri.sp_Expediente_Insert');
  
  return result.recordset[0];
};
```

**Ventajas:**
- Abstracción del acceso a datos
- Facilita testing mediante mocks de repositorios
- Centralización de lógica de acceso a BD
- Reutilización en múltiples servicios
- Facilita cambio de implementación (SQL Server → PostgreSQL, etc.)

### Stored Procedures

Toda la lógica de negocio crítica está encapsulada en Stored Procedures de SQL Server. Esto garantiza:

- **Seguridad**: Prevención de SQL Injection mediante parámetros tipados
- **Performance**: Optimización de consultas en el servidor de BD
- **Integridad**: Reglas de negocio a nivel de base de datos
- **Auditoría**: Logging centralizado de operaciones críticas

**Ejemplo de Stored Procedure:**
```sql
CREATE PROCEDURE dicri.sp_Expediente_Insert
    @DatosGenerales NVARCHAR(MAX),
    @TecnicoID INT,
    @TipoExpedienteID INT
AS
BEGIN
    -- Validaciones de negocio
    -- Inserción de datos
    -- Retorno de resultado
END
```

## Testing

### Ejecutar Tests

```bash
npm test
```

### Estructura de Tests

Los tests utilizan Jest y Supertest para testing de endpoints:

- `tests/authController.test.ts` - Tests de autenticación
- `tests/authService.test.ts` - Tests de servicio de autenticación
- `tests/expedienteController.test.ts` - Tests de expedientes

### Ejemplo de Test

```typescript
describe('POST /api/auth/login', () => {
  it('should login successfully with valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'tecnico.01@mp.gt',
        password: 'DicriPass#2025'
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body).toHaveProperty('user');
  });
});
```

## Docker

### Construir Imagen

```bash
docker build -t dicri-backend .
```

### Ejecutar Contenedor

```bash
docker run -p 3000:3000 --env-file .env dicri-backend
```

Para más detalles sobre Docker Compose y orquestación de servicios, consultar [README_DOCKER.md](../README_DOCKER.md).

## Documentación de API

La documentación interactiva está disponible en Swagger UI:

**URL:** `http://localhost:3000/api-docs`

Incluye:
- Descripción de todos los endpoints
- Parámetros requeridos y opcionales
- Ejemplos de requests y responses
- Prueba de endpoints directamente desde el navegador
- Esquemas de datos y validaciones

## Troubleshooting

### Error de Conexión a Base de Datos

1. Verificar que las variables de entorno en `.env` estén correctamente configuradas
2. Verificar que SQL Server esté corriendo y accesible
3. Verificar configuración de firewall (puerto 1433 debe estar abierto)
4. Verificar credenciales de acceso a la base de datos
5. Verificar que TCP/IP esté habilitado en SQL Server Configuration Manager
6. Verificar que el servidor SQL permita conexiones remotas

### Error de Autenticación

1. Verificar que los usuarios estén creados en la base de datos ejecutando `03_insert_users.sql`
2. Verificar que los hashes de contraseñas sean correctos
3. Ejecutar scripts de diagnóstico si es necesario (`04_diagnostico_hash.sql` y siguientes)
4. Verificar que el `JWT_SECRET` en `.env` esté configurado correctamente

### Puerto 3000 en Uso

Cambiar el puerto en `.env`:
```env
PORT=3001
```

O detener el proceso que está usando el puerto:
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill
```

### Errores de Compilación TypeScript

1. Verificar que todas las dependencias estén instaladas: `npm install`
2. Verificar que `tsconfig.json` esté correctamente configurado
3. Limpiar carpeta `dist/` y recompilar: `rm -rf dist && npm run build`

### Errores de Stored Procedures

1. Verificar que todos los scripts SQL se hayan ejecutado en orden
2. Verificar que el esquema `dicri` exista en la base de datos
3. Verificar permisos del usuario de la base de datos para ejecutar Stored Procedures

## Decisiones Técnicas

### ¿Por qué Stored Procedures?

- **Seguridad**: Previene SQL Injection mediante parámetros tipados
- **Performance**: Optimización de consultas en el servidor de BD con planes de ejecución precompilados
- **Integridad**: Reglas de negocio a nivel de base de datos garantizan consistencia
- **Auditoría**: Facilita logging y trazabilidad de operaciones críticas
- **Requisito del proyecto**: Uso exclusivo de Stored Procedures para toda la lógica de negocio

### ¿Por qué Repository Pattern?

- **Separación de responsabilidades**: Abstrae completamente el acceso a datos del resto de la aplicación
- **Testabilidad**: Permite mockear repositorios fácilmente en tests unitarios
- **Flexibilidad**: Facilita cambio de implementación (SQL Server → PostgreSQL, MongoDB, etc.)
- **Reutilización**: Múltiples servicios pueden usar los mismos repositorios
- **Mantenibilidad**: Centralización de lógica de acceso a datos

### ¿Por qué TypeScript?

- **Type Safety**: Detección temprana de errores en tiempo de compilación
- **IntelliSense**: Mejor experiencia de desarrollo con autocompletado y sugerencias
- **Documentación**: Los tipos sirven como documentación viva del código
- **Refactoring**: Más seguro y confiable al cambiar código
- **Escalabilidad**: Facilita el mantenimiento en proyectos grandes

### ¿Por qué Express en lugar de NestJS?

- **Flexibilidad**: Permite estructuración rápida sin imponer arquitectura rígida
- **Simplicidad**: Ideal para prototipado rápido en pruebas técnicas
- **Control**: Mayor control sobre la estructura del proyecto
- **Tiempo**: Menor tiempo de setup inicial comparado con frameworks más complejos

## Notas Adicionales

### Variables de Entorno

El archivo `.env` no debe ser commiteado al repositorio. Asegúrate de que esté en `.gitignore`. Para producción, usar variables de entorno del sistema o servicios de gestión de secrets.

### Seguridad en Producción

- Cambiar `JWT_SECRET` por un valor seguro y aleatorio
- Habilitar HTTPS en producción
- Configurar CORS adecuadamente para el dominio del frontend
- Revisar y ajustar headers de seguridad de Helmet según necesidades
- Implementar rate limiting para prevenir abuso de la API

### Mejoras Futuras

- Implementar paginación en endpoints de listado
- Agregar filtros avanzados en búsquedas
- Implementar cache para catálogos frecuentemente consultados
- Agregar logging estructurado (Winston, Pino)
- Implementar métricas y monitoreo (Prometheus, Grafana)
- Agregar documentación OpenAPI más completa
- Implementar versionado de API

### Problemas Conocidos

- Los archivos compilados en `dist/` se incluyen en el repositorio. Considerar ignorarlos en `.gitignore` si se prefiere compilar en CI/CD
- El manejo de errores de conexión a BD podría mejorarse con retry logic
- Falta validación de formato de fechas en algunos endpoints

## Referencias

- [README Principal](../README.md) - Documentación general del proyecto
- [README Docker](../README_DOCKER.md) - Guía de despliegue con Docker
- [Express.js Documentation](https://expressjs.com/) - Documentación oficial de Express
- [TypeScript Documentation](https://www.typescriptlang.org/) - Documentación oficial de TypeScript
- [mssql Documentation](https://www.npmjs.com/package/mssql) - Documentación del driver mssql

---

**Backend API - DICRI**
