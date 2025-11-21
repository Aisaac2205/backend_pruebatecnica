# DICRI Backend - API RESTful

> **Backend del Sistema de Gestión de Evidencia Criminalística**

API RESTful desarrollada con Node.js, Express y TypeScript que gestiona la lógica de negocio para el sistema DICRI. Toda la lógica crítica está encapsulada en Stored Procedures de SQL Server, garantizando integridad y seguridad de datos.

## 📋 Descripción

El backend de DICRI proporciona una API RESTful completa para la gestión de expedientes e indicios criminalísticos. Utiliza el patrón Repository para abstraer el acceso a datos y delega toda la lógica de negocio a Stored Procedures de SQL Server.

### Características Principales

-  **Autenticación JWT**: Tokens seguros para autenticación
-  **Autorización por Roles**: Control de acceso basado en roles (Técnico/Coordinador)
-  **Repository Pattern**: Abstracción del acceso a datos
-  **Stored Procedures**: Toda la lógica de negocio en SQL Server
-  **Swagger Documentation**: Documentación interactiva de la API
-  **Seguridad**: Helmet, CORS, validación de entrada
-  **Testing**: Suite de tests con Jest y Supertest

##  Arquitectura

### Estructura de Carpetas

```
dicri-backend/
├── src/
│   ├── app.ts                 # Configuración de Express
│   ├── server.ts              # Punto de entrada del servidor
│   ├── config/
│   │   └── db.ts              # Configuración de conexión SQL Server
│   ├── controllers/           # Controladores de rutas
│   │   ├── authController.ts
│   │   ├── expedienteController.ts
│   │   ├── indicioController.ts
│   │   ├── catalogoController.ts
│   │   └── reportController.ts
│   ├── services/              # Lógica de negocio (orquestación)
│   │   ├── authService.ts
│   │   ├── expedienteService.ts
│   │   ├── indicioService.ts
│   │   ├── catalogoService.ts
│   │   └── reportService.ts
│   ├── db/                    # Repositorios (Repository Pattern)
│   │   ├── authRepository.ts
│   │   ├── expedienteRepository.ts
│   │   ├── indicioRepository.ts
│   │   ├── catalogoRepository.ts
│   │   └── reportRepository.ts
│   ├── routes/                # Definición de rutas
│   │   ├── authRoutes.ts
│   │   ├── expedienteRoutes.ts
│   │   ├── indicioRoutes.ts
│   │   ├── catalogoRoutes.ts
│   │   └── reportRoutes.ts
│   ├── middlewares/           # Middlewares
│   │   └── authMiddleware.ts  # Autenticación y autorización
│   ├── types/                 # Definiciones TypeScript
│   │   └── index.ts
│   └── utils/                 # Utilidades
├── database/                  # Scripts SQL
│   ├── 01_tables.sql          # Esquema y tablas
│   ├── 02_procedures.sql      # Stored Procedures
│   └── 03_insert_users.sql    # Datos iniciales
├── tests/                     # Tests unitarios
│   ├── setup.ts
│   ├── authController.test.ts
│   ├── authService.test.ts
│   └── expedienteController.test.ts
├── dist/                      # Código compilado (TypeScript → JavaScript)
├── Dockerfile                 # Configuración Docker
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

##  Stack Tecnológico

- **Node.js** 18+
- **Express** - Framework web
- **TypeScript** - Tipado estático
- **mssql** - Driver para SQL Server
- **jsonwebtoken** - Autenticación JWT
- **helmet** - Seguridad HTTP
- **cors** - Cross-Origin Resource Sharing
- **morgan** - Logging de requests
- **dotenv** - Variables de entorno
- **swagger-ui-express** - Documentación de API
- **Jest** + **Supertest** - Testing

##  Instalación y Configuración

### Requisitos Previos

- Node.js 18 o superior
- npm o pnpm
- SQL Server (local o remoto)
- Acceso a la base de datos configurada

### 1. Instalación de Dependencias

```bash
cd dicri-backend
npm install
```

### 2. Configuración de Variables de Entorno

Crear archivo `.env` en la raíz de `dicri-backend/`:

```env
# Base de Datos
DB_SERVER=tu-servidor-sql.database.windows.net
DB_NAME=DB_DICRI
DB_USER=tu-usuario
DB_PASSWORD=tu-contraseña
DB_PORT=1433
DB_ENCRYPT=true

# JWT
JWT_SECRET=tu-secret-key-super-segura-aqui

# Servidor
PORT=3000
NODE_ENV=development
```

> **Nota**: El nombre de la variable es `DB_NAME` en el código (ver `src/config/db.ts`), aunque en `docker-compose.yml` se usa `DB_DATABASE`. Ajusta según tu configuración.

### 3. Configuración de Base de Datos

Ejecutar los scripts SQL en orden (ver sección [Scripts SQL](#-scripts-sql)):

1. `01_tables.sql` - Crear esquema y tablas
2. `02_procedures.sql` - Crear Stored Procedures
3. `03_insert_users.sql` - Insertar usuarios de prueba
4. `11_insert_tipos_expediente.sql` - Insertar catálogos

### 4. Compilar TypeScript

```bash
npm run build
```

### 5. Ejecutar el Servidor

#### Modo Producción
```bash
npm start
```

#### Modo Desarrollo (con hot-reload)
```bash
npm run dev
```

El servidor estará disponible en `http://localhost:3000`

## 📡 Endpoints de la API

### Autenticación

| Método | Endpoint | Descripción | Autenticación |
|--------|----------|-------------|---------------|
| POST | `/api/auth/login` | Iniciar sesión | No requerida |

**Request Body:**
```json
{
  "email": "tecnico.01@mp.gt",
  "password": "DicriPass#2025"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "usuarioID": 1,
    "emailLogin": "tecnico.01@mp.gt",
    "rol": "Tecnico",
    "nombreCompleto": "Técnico 01"
  }
}
```

### Expedientes

| Método | Endpoint | Descripción | Rol Requerido |
|--------|----------|-------------|---------------|
| GET | `/api/expedientes` | Listar expedientes | Cualquiera autenticado |
| GET | `/api/expedientes/:id` | Obtener expediente por ID | Cualquiera autenticado |
| POST | `/api/expedientes` | Crear expediente | Técnico |
| PUT | `/api/expedientes/:id/review` | Revisar/aprobar expediente | Coordinador |
| DELETE | `/api/expedientes/:id` | Eliminar expediente | Técnico/Coordinador |

### Indicios

| Método | Endpoint | Descripción | Rol Requerido |
|--------|----------|-------------|---------------|
| GET | `/api/indicios/:expedienteId` | Listar indicios de un expediente | Cualquiera autenticado |
| POST | `/api/indicios` | Crear indicio | Técnico |

### Catálogos

| Método | Endpoint | Descripción | Autenticación |
|--------|----------|-------------|---------------|
| GET | `/api/catalogos/tipo-expediente` | Obtener tipos de expediente | No requerida |

### Reportes

| Método | Endpoint | Descripción | Autenticación |
|--------|----------|-------------|---------------|
| GET | `/api/reports` | Generar reporte | Requerida |

### Otros

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api-docs` | Swagger UI (documentación interactiva) |

##  Autenticación y Autorización

### JWT Tokens

Después de hacer login exitoso, incluye el token en las peticiones:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Roles

- **Tecnico**: Puede crear y gestionar expedientes e indicios
- **Coordinador**: Puede revisar y aprobar expedientes

### Middleware

- `authMiddleware`: Verifica que el token JWT sea válido
- `roleMiddleware`: Verifica que el usuario tenga el rol requerido

**Ejemplo de uso:**
```typescript
router.post('/', roleMiddleware(['Tecnico']), expedienteController.create);
```

##  Scripts SQL

### Orden de Ejecución

1. **01_tables.sql**
   - Crea el esquema `dicri`
   - Crea todas las tablas: `Usuarios`, `Expedientes`, `Indicios`, `TipoExpediente`
   - Define constraints, índices y relaciones

2. **02_procedures.sql**
   - Crea todos los Stored Procedures:
     - `sp_Auth_Login` - Autenticación de usuarios
     - `sp_Expediente_Insert` - Crear expediente
     - `sp_Expediente_GetAll` - Listar expedientes
     - `sp_Expediente_GetById` - Obtener expediente
     - `sp_Expediente_UpdateStatus` - Actualizar estado (revisión)
     - `sp_Expediente_Delete` - Eliminar expediente
     - `sp_Indicio_Insert` - Crear indicio
     - `sp_Indicio_GetByExpediente` - Listar indicios
     - `sp_Catalogo_GetTiposExpediente` - Obtener catálogos
     - `sp_Report_Get` - Generar reportes

3. **03_insert_users.sql**
   - Inserta usuarios de prueba:
     - `tecnico.01@mp.gt` / `DicriPass#2025`
     - `coordinador.01@mp.gt` / `DicriPass#2025`

4. **11_insert_tipos_expediente.sql**
   - Inserta tipos de expediente en el catálogo

### Scripts de Diagnóstico (Opcional)

Si hay problemas con autenticación/hashes:
- `04_diagnostico_hash.sql` hasta `12_actualizar_hash_coordinador.sql`

##  Testing

### Ejecutar Tests

```bash
npm test
```

### Estructura de Tests

Los tests utilizan **Jest** y **Supertest** para testing de endpoints:

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
  });
});
```

##  Docker

### Construir Imagen

```bash
docker build -t dicri-backend .
```

### Ejecutar Contenedor

```bash
docker run -p 3000:3000 --env-file .env dicri-backend
```

Ver [README_DOCKER.md](../README_DOCKER.md) para más detalles sobre Docker Compose.

##  Repository Pattern

El patrón Repository abstrae el acceso a datos:

```typescript
// Repository
export const createExpediente = async (datosGenerales: string, tecnicoId: number, tipoExpedienteId: number) => {
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
- Facilita testing (mock de repositorios)
- Centralización de lógica de acceso a BD
- Reutilización en múltiples servicios

##  Stored Procedures

Toda la lógica de negocio está en Stored Procedures:

**Ejemplo: `sp_Expediente_Insert`**
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

**Ventajas:**
- Seguridad: Prevención de SQL Injection
- Performance: Optimización en el servidor
- Integridad: Reglas de negocio a nivel BD
- Auditoría: Logging centralizado

##  Documentación de API

La documentación interactiva está disponible en Swagger UI:

**URL:** `http://localhost:3000/api-docs`

Incluye:
- Descripción de todos los endpoints
- Parámetros requeridos
- Ejemplos de requests/responses
- Prueba de endpoints directamente desde el navegador

##  Troubleshooting

### Error de Conexión a Base de Datos

1. Verificar variables de entorno en `.env`
2. Verificar que SQL Server esté corriendo
3. Verificar firewall (puerto 1433)
4. Verificar credenciales de acceso
5. Verificar que TCP/IP esté habilitado en SQL Server Configuration Manager

### Error de Autenticación

1. Verificar que los usuarios estén creados en la BD
2. Verificar que los hashes de contraseñas sean correctos
3. Ejecutar scripts de diagnóstico si es necesario

### Puerto 3000 en Uso

Cambiar el puerto en `.env`:
```env
PORT=3001
```

O detener el proceso que está usando el puerto.

##  Decisiones Técnicas

### ¿Por qué Stored Procedures?

- **Seguridad**: Previene SQL Injection
- **Performance**: Optimización en el servidor de BD
- **Integridad**: Reglas de negocio a nivel de base de datos
- **Auditoría**: Facilita logging y trazabilidad

### ¿Por qué Repository Pattern?

- **Separación de responsabilidades**: Abstrae acceso a datos
- **Testabilidad**: Permite mockear repositorios
- **Flexibilidad**: Facilita cambio de implementación
- **Reutilización**: Múltiples servicios pueden usar los mismos repositorios

### ¿Por qué TypeScript?

- **Type Safety**: Detección temprana de errores
- **IntelliSense**: Mejor experiencia de desarrollo
- **Documentación**: Los tipos sirven como documentación
- **Refactoring**: Más seguro y confiable

##  Referencias

- [README Principal](../README.md)
- [README Docker](../README_DOCKER.md)
- [Express.js Documentation](https://expressjs.com/)
- [TypeScript Documentation](https://www.typescriptlang.org/)
- [mssql Documentation](https://www.npmjs.com/package/mssql)

---

**Backend API - DICRI** 
