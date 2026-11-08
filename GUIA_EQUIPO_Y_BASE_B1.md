# Guía Operativa de Desarrollo e Integración — Proyecto Interadds (Bimestre 1)

Este documento contiene el estado actual de la arquitectura base del monolito (Web B1), las instrucciones paso a paso para levantar el entorno local, las reglas de ramas/Pull Requests (**RNF-09**) y los contratos de integración (qué debe usar cada integrante de lo que ya está construido).

---

## 1. ¿Qué ya está implementado y listo en la rama `main`? (Base de Plataforma — Mateo Quisilema)

La base técnica del monolito ya fue configurada, probada y migrada. **Nadie debe volver a inicializar Next.js ni reconfigurar Prisma desde cero.** Lo que ya tienen disponible es:

1. **Servidor Híbrido Node.js + Next.js + Socket.IO (`src/server.ts` — `RNF-10`):**
   - El comando `npm run dev` levanta nuestro servidor Node personalizado en `http://localhost:3000`.
   - Ya incluye la instancia de `Socket.IO` acoplada al mismo servidor HTTP (`path: '/api/socketio'`) y expuesta globalmente como `global.io` para emitir eventos en tiempo real desde cualquier ruta API o módulo.
2. **Arquitectura Modular de 5 Verticales (`src/modules/` — `RNF-10`):**
   - `src/modules/auth/` (Sebas Ramos)
   - `src/modules/contracts/` (Danna Morales)
   - `src/modules/signatures/` (Domenica Cardenas)
   - `src/modules/payments/` (Mateo Quisilema)
   - `src/modules/chat/` (Salma Morales)
   - `src/app/` (Vistas UI y páginas de Sebas Sarasti + API Routes)
3. **Esquema Completo de Base de Datos y Migración Inicial (`prisma/schema.prisma`):**
   - Ya están modeladas las **10 entidades de B1** y los **Enums oficiales**, incluyendo los 7 estados inquebrantables del contrato (`GENERADO`, `FIRMADO_POR_UNA_PARTE`, `VIGENTE`, `ANTICIPO_PAGADO`, `CONTENIDO_ENTREGADO`, `CONTENIDO_APROBADO`, `COMPLETADO` — **RNF-22**).
   - El singleton de conexión a BD ya existe en `src/lib/prisma.ts`.
4. **Primitivas Criptográficas y de Seguridad (`src/lib/crypto/`):**
   - Derivación de contraseñas con Bcrypt y sal (`RS-12` / `RNF-03`).
   - Generador de números/tokens aleatorios criptográficamente seguro CSPRNG (`RS-15` / `RS-07`).
   - Controlador de fechas de expiración y caducidad (`RS-42`).
5. **Plantilla de Variables de Entorno (`.env.example` — `RS-11` y `RNF-02`):**
   - Define todas las variables requeridas sin exponer secretos en el repositorio.

---

## 2. Cómo levantar el proyecto en tu computadora (Paso a Paso)

Sigue estos comandos en orden desde tu terminal (Git Bash):

```bash
# 1. Clonar el repositorio y entrar a la carpeta
git clone [https://github.com/JuanMateoQ/Interadds.git](https://github.com/JuanMateoQ/Interadds.git)
cd Interadds

# 2. Instalar dependencias (Prisma 6 y Vitest 3 ya están fijados)
npm install

# 3. Crear tu archivo .env local a partir de la plantilla
cp .env.example .env
IMPORTANTE SOBRE TU ARCHIVO .env:
Abre tu archivo .env en VS Code y en la línea DATABASE_URL reemplaza la contraseña por la clave real de tu PostgreSQL local (pgAdmin). NUNCA subas tu archivo .env a GitHub (RS-11, RNF-09).

# 4. Aplicar la migración inicial en tu PostgreSQL local (crea la BD interadds_b1 automáticamente)
npx prisma migrate dev

# 5. Levantar el servidor de desarrollo
npm run dev

## 3. Reglas de Git, Nombres de Ramas y Pull Requests (`RNF-09`)

1. **Prohibido hacer `push` directo a `main`:** Todo cambio debe entrar mediante **Pull Request (PR)** con al menos 1 revisión aprobada de otro compañero.
2. **Convención obligatoria de ramas por integrante:**
   Antes de escribir código, asegúrate de estar en `main` actualizado (`git checkout main && git pull origin main`) y crea tu rama con el nombre asignado:

| Integrante | Vertical | Comando para crear su rama |
| :--- | :--- | :--- |
| **Sebas Ramos** | Identidad, sesiones y acceso | `git checkout -b feat/sebas-ramos-auth` |
| **Danna Morales** | Catálogo, semillas y contratos | `git checkout -b feat/danna-catalog-and-contracts` |
| **Domenica Cardenas** | Firma digital, CA y evidencias | `git checkout -b feat/domenica-ca-and-signatures` |
| **Mateo Quisilema** | Pagos PayPal, aprobación y cierre | `git checkout -b feat/mateo-paypal-and-approval` |
| **Salma Morales** | Chat Socket.IO, entregas y avisos | `git checkout -b feat/salma-chat-and-deliverables` |
| **Sebas Sarasti** | Frontend, visor protegido y UI | `git checkout -b feat/sebas-sarasti-frontend` |

3. **Commits atómicos y claros:** Usa prefijos convencionales e incluye los IDs de los requerimientos que cumples, por ejemplo:
   ```bash
   git commit -m "feat(auth): implement user registration and generic login error (RF-04, RF-05, RS-04)"
   ```

---

## 4. ¿Qué debe importar y usar cada compañero de lo que ya dejó Mateo?

Para mantener la consistencia del monolito y cumplir los controles del **Common Criteria**, **no creen nuevos clientes de Prisma ni usen `Math.random()`**. Importen siempre estos módulos base:

### A. Para Sebas Ramos (Módulo `src/modules/auth/`)
* **Conexión a BD:** `import { prisma } from '@/lib/prisma';`
* **Hash y verificación de contraseñas (`RS-12`, `RNF-03`):**
  ```typescript
  import { hashPassword, verifyPassword } from '@/lib/crypto/password';
  // En registro (RF-04): const passwordHash = await hashPassword(plainPassword);
  // En login (RF-05): const isValid = await verifyPassword(plainPassword, user.passwordHash);
  ```
* **Token de recuperación de clave de un solo uso (`RF-07`, `RS-03`, `RS-07`, `RS-15`):**
  ```typescript
  import { generateSecureRandomHex } from '@/lib/crypto/random';
  import { createExpirationDate, isExpired } from '@/lib/crypto/expiration';
  // Generar token de 32 bytes hex y expiración de 15 minutos (RS-42):
  const token = generateSecureRandomHex(32);
  const expiresAt = createExpirationDate(15);
  ```

### B. Para Danna Morales (Módulo `src/modules/contracts/` y `prisma/seed.ts`)
* **Conexión a BD:** `import { prisma } from '@/lib/prisma';`
* **Semillas (`prisma/seed.ts` — Prioridad alta para pruebas del equipo):**
  Usa `hashPassword` de `@/lib/crypto/password` para crear las contraseñas de los usuarios semilla (`CLIENTE`, `PROVEEDOR`, `ADMIN_SISTEMA`) y crea los **7 contratos de prueba (uno en cada estado del Enum `ContractStatus`)** para que todos podamos probar nuestras pantallas y endpoints sin bloqueo.
* **Estados del contrato (`RNF-22`):** Usa siempre el enum `ContractStatus` de `@prisma/client`.

### C. Para Domenica Cardenas (Módulo `src/modules/signatures/`)
* **Variables de la CA Emisora (`RS-11`):** Lee las claves de la CA desde `process.env.CA_ISSUER_PRIVATE_KEY_PEM`, `process.env.CA_ISSUER_CERT_PEM` y `process.env.CA_ROOT_CERT_PEM`.
* **Nonces de firma y números de serie (`RF-17`, `RS-10`, `RS-15`):**
  ```typescript
  import { generateNonce, generateSecureRandomHex } from '@/lib/crypto/random';
  ```
* **Re-autenticación antes de firmar (`RS-26`):** Usa `verifyPassword` de `@/lib/crypto/password`.
* **Vigencia de certificados (`RS-42`):** Usa `isExpired` de `@/lib/crypto/expiration`.
* **Integración con Pagos y Entrega:** Expón una función `recordSignatureEvidence(...)` en tu módulo para que los servicios de Mateo (pagos y aprobación) y Salma (entrega de archivo) registren las evidencias `ORIGEN` (**RS-16**) y `RECEPCION` (**RS-17**).

### D. Para Salma Morales (Módulo `src/modules/chat/`)
* **Servidor Socket.IO (`RNF-04`, `RNF-10`):** En `src/server.ts` ya está creado `const io = new SocketIOServer(...)` y asignado a `global.io`. Crea tu función `registerChatSocketHandlers(io)` en `src/modules/chat/socket.ts` e impórtala en `src/server.ts`.
* **Regla de negocio del chat (`RF-23`):** Antes de unir a un usuario a la sala `contract:${contractId}`, verifica con `prisma.contract.findUnique` que el usuario sea `clientId` o `providerId` y que el estado del contrato haya alcanzado al menos `ANTICIPO_PAGADO` (es decir, que el módulo de pagos de Mateo ya haya capturado el primer 50 %).

### E. Para Sebas Sarasti (Frontend en `src/app/`)
* **Integración con los botones de PayPal y Aprobación de Mateo:**
  - Crear orden del 50 % (anticipo o saldo): `POST /api/payments/create-order` enviando `{ contractId, userId, password, installment: 'ANTICIPO' | 'SALDO' }`.
  - Capturar orden tras aprobar en PayPal: `POST /api/payments/capture-order` enviando `{ contractId, paypalOrderId, userId }`.
  - Aprobar entregable del proveedor (`RF-27`): `POST /api/contracts/[id]/approve-deliverable`.
  - Consultar recibos e historial de pagos (`RF-22`): `GET /api/payments/history?userId=...`.

---

## 5. Reglas de Alcance Inquebrantables (Qué NO hacer en Bimestre 1)

1. **No usar `Math.random()`** para tokens, nonces o IDs (viola `RS-15`).
2. **No enviar el texto del contrato ni enlaces públicos al contrato por correo o consola** (`RS-44`, `RS-45`, `RF-15`, `RF-36`).
3. **No implementar componentes exclusivos de Bimestre 2:** Sin Docker, sin microservicios separados, sin JWT asimétrico, sin webhooks de PayPal y sin panel de disputas/reembolsos.
4. **Validación dual obligatoria (`RNF-01`):** Todo formulario debe validarse tanto en el cliente (Sebas Sarasti) como en el servidor (cada dueño de módulo).