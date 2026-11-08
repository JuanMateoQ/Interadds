# Matriz de Trazabilidad Técnica y Defensa por Integrante — Interadds (Bimestre 1)

Este documento cumple con el requisito de trazabilidad exhaustiva del **Bimestre 1 (Web B1 - 120 pts)** y los **25 componentes de seguridad del Common Criteria (CC:2022)** implementados en el código del monolito. Detalla por cada integrante sus entregables, IDs de requisitos (`RF`, `RNF`, `RS`), rutas exactas de archivos, funciones clave para la defensa oral y guía de Pull Requests (`RNF-09`).

---

## 1. Mateo Quisilema — Pagos y Plataforma (19 pts Web B1 | 11 pts Seg B1)

### 1.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Common Criteria (RS) en Código |
| :--- | :---: | :--- | :--- | :--- |
| Repositorio, ramas/PRs, Next.js con servidor Node propio, Prisma + migración inicial, `.env.example`, hash de claves y generador aleatorio seguro | 5 pts | RF-05 (base hash) | RNF-02, RNF-03, RNF-09, RNF-10 | **RS-11** (`FCS_CKM.3`), **RS-12** (`FCS_CKM.5`), **RS-15** (`FCS_RNG.1`), **RS-42** (`FMT_SAE.1`) |
| Cuentas Sandbox de PayPal y módulo de pagos detrás de interfaz propia | 2 pts | RF-20 | RNF-02, RNF-24 | **RS-11** (`FCS_CKM.3`) |
| Pago del anticipo (50 %) y del saldo (50 %) con PayPal Orders v2 en servidor, idempotencia y recibos | 6 pts | RF-20, RF-21, RF-22, RF-28 | RNF-01, RNF-22, RNF-24 | **RS-16** (`FCO_NRO.2`), **RS-17** (`FCO_NRR.2`), **RS-19** (`FDP_ACF.1`), **RS-26** (`FIA_UAU.6`) |
| Aprobación del contenido entregable y desbloqueo del pago del saldo | 2 pts | RF-27 | RNF-22 | **RS-16** (`FCO_NRO.2`), **RS-17** (`FCO_NRR.2`), **RS-19** (`FDP_ACF.1`) |
| Medición de rendimiento (Lighthouse y consulta con índice) | 1 pt | — | RNF-06 | — |
| `README.md` con arquitectura, esquema de BD, sección «Uso de IA» y tag `v1.0-b1` | 3 pts | — | RNF-08, RNF-09 | — |

### 1.2. Mapa Exacto de Archivos Relacionados
* **Infraestructura y Base:** `src/server.ts`, `prisma/schema.prisma`, `prisma/migrations/*_init_monolith_b1/migration.sql`, `src/lib/prisma.ts`, `.env.example`, `.gitignore`.
* **Primitivas Criptográficas (`RS-12`, `RS-15`, `RS-42`):** `src/lib/crypto/password.ts`, `src/lib/crypto/random.ts`, `src/lib/crypto/expiration.ts`.
* **Módulo de Pagos y Aprobación:**
  - `src/modules/payments/domain/payment-gateway.interface.ts` (`IPaymentGateway` — `RNF-24`)
  - `src/modules/payments/infrastructure/paypal.adapter.ts` (`PayPalSandboxAdapter` — `RNF-24`)
  - `src/modules/payments/application/payment.service.ts` (`PaymentService` — `RF-20`, `RF-21`, `RF-28`, `RNF-22`)
  - `src/modules/payments/application/approval.service.ts` (`DeliverableApprovalService` — `RF-27`)
* **Rutas API:** `src/app/api/payments/create-order/route.ts`, `src/app/api/payments/capture-order/route.ts`, `src/app/api/payments/history/route.ts`, `src/app/api/contracts/[id]/approve-deliverable/route.ts`.
* **Pruebas y Documentación:** `src/modules/payments/__tests__/payment.test.ts`, `README.md`, `GUIA_EQUIPO_Y_BASE_B1.md`, `TRAZABILIDAD_EQUIPO_B1.md`.

### 1.3. Explicación para Defensa Individual
* **`hashPassword()` y `verifyPassword()` en `src/lib/crypto/password.ts`:** Materializan **RS-12 (`FCS_CKM.5`)** y **RNF-03** derivando hashes con `bcrypt` (factor de costo 12 y sal única por usuario).
* **`generateSecureRandomHex()`, `generateNonce()` y `buildIdempotencyKey()` en `src/lib/crypto/random.ts`:** Materializan **RS-15 (`FCS_RNG.1`)** empleando `crypto.randomBytes` del CSPRNG del sistema operativo en lugar de `Math.random()`.
* **`isExpired()` en `src/lib/crypto/expiration.ts`:** Materializa **RS-42 (`FMT_SAE.1`)** verificando caducidad en UTC para tokens, certificados y autorizaciones temporales.
* **`PayPalSandboxAdapter` en `paypal.adapter.ts`:** Implementa `IPaymentGateway` (**RNF-24**), inyecta el encabezado `PayPal-Request-Id` para idempotencia (**RNF-22**) y aplica `AbortSignal.timeout(10000)` para que si PayPal tarda más de 10 s el pago quede `PENDIENTE` sin duplicar cobros.
* **`PaymentService.createPaymentOrder()` y `capturePaymentOrder()`:** Exigen re-autenticación (**RS-26**), validan pertenencia al contrato (**RS-19**), imponen que el anticipo solo se pague en estado `VIGENTE` y el saldo solo en `CONTENIDO_APROBADO` (**RNF-22**), calculan el 50 % en servidor y comprueban monto/moneda capturados antes de avanzar el estado.

---

## 2. Sebas Ramos — Identidad y Acceso (19 pts Web B1 | 11 pts Seg B1)

### 2.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Common Criteria (RS) en Código |
| :--- | :---: | :--- | :--- | :--- |
| Registro con validación en cliente y servidor y elección de rol (`CLIENTE`/`PROVEEDOR`), usuario y rol por defecto | 4 pts | RF-04 | RNF-01, RNF-03 | **RS-01** (`FIA_ATD.1`), **RS-06** (`FIA_SOS.1`), **RS-38** (`FMT_SMR.1`), **RS-40** (`FMT_MSA.3`), **RS-41** (`FMT_MOF.1`) |
| Inicio de sesión con mensaje genérico, sesiones seguras, cierre de sesión y protección de rutas | 6 pts | RF-05, RF-06, RF-08 | RNF-01, RNF-03 | **RS-02** (`FIA_USB.1`), **RS-04** (`FIA_UAU.7`), **RS-08** (`FIA_UID.2`), **RS-09** (`FIA_UAU.2`), **RS-37** (`FTA_SSL.4`) |
| Recuperación de contraseña con token de un solo uso y caducidad en consola + edición de perfil | 4 pts | RF-07, RF-09 | RNF-01 | **RS-03** (`FIA_UAU.5`), **RS-07** (`FIA_SOS.2`), **RS-15** (`FCS_RNG.1`), **RS-42** (`FMT_SAE.1`) |
| Semillas de usuarios por rol, regla de revisión de PR, ejecutor de pruebas en un comando y pruebas de autenticación | 5 pts | RF-04 a RF-08 | RNF-07, RNF-09 | Pruebas de **RS-04**, **RS-06**, **RS-08**, **RS-09**, **RS-37**, **RS-41** |

### 2.2. Mapa Exacto de Archivos Relacionados
* **Modelos Prisma:** `User`, `ProviderProfile`, `PasswordResetToken` en `prisma/schema.prisma`.
* **Servicios y Lógica:** `src/modules/auth/application/auth.service.ts`, `src/modules/auth/application/session.service.ts`, `src/modules/auth/application/profile.service.ts`, `src/modules/auth/domain/validators.ts`.
* **Middleware de Autorización:** `src/middleware.ts` (protección de rutas privadas y verificación de rol).
* **Rutas API:** `src/app/api/auth/register/route.ts`, `src/app/api/auth/login/route.ts`, `src/app/api/auth/logout/route.ts`, `src/app/api/auth/recover/route.ts`, `src/app/api/auth/reset-password/route.ts`, `src/app/api/profile/route.ts`.
* **Pruebas:** `src/modules/auth/__tests__/auth.test.ts`.

### 2.3. Explicación para Defensa Individual
* **`validatePasswordStrength()` en `validators.ts`:** Cumple **RS-06 (`FIA_SOS.1`)** rechazando en servidor contraseñas que no cumplan longitud mínima, mayúsculas, minúsculas y números.
* **`AuthService.register()`:** Cumple **RS-40 (`FMT_MSA.3`)** asignando por defecto `role: 'CLIENTE'` y `isActive: true`, y **RS-41 (`FMT_MOF.1`)** bloqueando cualquier intento de auto-asignarse el rol `ADMIN_SISTEMA` desde el formulario público.
* **`AuthService.login()`:** Cumple **RS-04 (`FIA_UAU.7`)** devolviendo exactamente el mismo mensaje (`"Credenciales inválidas"`) y código `401` tanto si el correo no existe como si la contraseña falla, evitando enumeración de cuentas.
* **`SessionService` y `middleware.ts`:** Cumplen **RS-02 (`FIA_USB.1`)**, **RS-08 (`FIA_UID.2`)**, **RS-09 (`FIA_UAU.2`)** y **RS-37 (`FTA_SSL.4`)** vinculando `userId` y `role` a una cookie `HttpOnly; SameSite=Lax` e invalidándola en servidor al cerrar sesión.
* **`AuthService.requestPasswordReset()` y `resetPassword()`:** Cumplen **RS-03 (`FIA_UAU.5`)** y **RS-07 (`FIA_SOS.2`)** generando un token CSPRNG de un solo uso con caducidad de 15 minutos (`used = true` tras consumirse).

---

## 3. Danna Morales — Catálogo y Contrato (19 pts Web B1 | 11 pts Seg B1)

### 3.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Common Criteria (RS) en Código |
| :--- | :---: | :--- | :--- | :--- |
| Modelos de servicio y contrato con índices + semillas en los 7 estados del contrato | 3 pts | RF-14 | RNF-06, RNF-22 | **RS-38** (`FMT_SMR.1`) |
| CRUD de servicios del Proveedor (crear, editar, pausar) y catálogo paginado con filtros | 6 pts | RF-01, RF-02, RF-03, RF-10, RF-11, RF-12 | RNF-01, RNF-05, RNF-06 | **RS-18** (`FDP_ACC.1`), **RS-19** (`FDP_ACF.1`), **RS-39** (`FMT_MSA.1`) |
| Solicitud de contratación y generación inmutable del contrato con cláusula 50/50 y hash SHA-256 | 4 pts | RF-13, RF-14 | RNF-21, RNF-22 | **RS-20** (`FDP_SDI.2`) |
| Control de acceso al contrato solo para las dos partes y sin enlaces públicos | 3 pts | RF-15, RF-36 | — | **RS-18** (`FDP_ACC.1`), **RS-19** (`FDP_ACF.1`), **RS-39** (`FMT_MSA.1`) |
| Pruebas automatizadas de CRUD, integridad del contrato y transiciones de estado | 3 pts | RF-10 a RF-15, RF-36 | RNF-07, RNF-22 | Pruebas de **RS-18**, **RS-19**, **RS-20**, **RS-39** |

### 3.2. Mapa Exacto de Archivos Relacionados
* **Modelos Prisma y Semillas:** `Category`, `MarketingService`, `Contract` en `prisma/schema.prisma`, `prisma/seed.ts`.
* **Servicios y Lógica:** `src/modules/contracts/application/catalog.service.ts`, `src/modules/contracts/application/contract.service.ts`, `src/modules/contracts/domain/contract-template.ts`, `src/modules/contracts/domain/state-machine.ts`.
* **Rutas API:** `src/app/api/services/route.ts`, `src/app/api/services/[id]/route.ts`, `src/app/api/contracts/route.ts`, `src/app/api/contracts/[id]/route.ts`.
* **Pruebas:** `src/modules/contracts/__tests__/contract.test.ts`.

### 3.3. Explicación para Defensa Individual
* **`ContractService.createContractFromService()`:** Toma la plantilla versionada (`v1.0` — **RNF-21**), calcula la cláusula 50 % anticipo (`advanceAmount`) y 50 % saldo (`balanceAmount`), congela el texto y calcula su hash SHA-256 con `crypto.createHash('sha256')` (**RF-14**).
* **`ContractService.verifyContractIntegrity()`:** Cumple **RS-20 (`FDP_SDI.2` - Stored data integrity)** recalculando el SHA-256 del texto almacenado cada vez que se abre o se intenta firmar el contrato; si difiere de `sha256Hash`, bloquea la operación por alteración.
* **`ContractService.getContractForParty()`:** Cumple **RF-15**, **RF-36**, **RS-18 (`FDP_ACC.1`)** y **RS-19 (`FDP_ACF.1`)** verificando que `session.userId === contract.clientId || session.userId === contract.providerId`. Incluso si un `ADMIN_SISTEMA` o un tercero autenticado intenta leer el contrato, devuelve `403 Forbidden`.
* **`assertValidTransition()` en `state-machine.ts`:** Cumple **RNF-22** y **RS-39 (`FMT_MSA.1`)** permitiendo avanzar el estado únicamente en el orden estricto de los 7 estados del happy path.

---

## 4. Domenica Cardenas — Firma Digital, CA y Evidencias (19 pts Web B1 | 11 pts Seg B1)

### 4.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Common Criteria (RS) en Código |
| :--- | :---: | :--- | :--- | :--- |
| CA interna de dos niveles (raíz offline y emisora), emisión de certificados desde CSR/clave pública y vigencia | 5 pts | RF-16 | RNF-02 | **RS-10** (`FCS_CKM.1`), **RS-11** (`FCS_CKM.3`), **RS-42** (`FMT_SAE.1`), **RS-46** (`FMT_SMF.1`) |
| Generación del par de claves ECDSA P-256 en navegador con WebCrypto | 3 pts | RF-16, RF-17 | — | **RS-10** (`FCS_CKM.1`), **RS-14** (`FCS_CKM.4`) |
| Firma digital del contrato con re-autenticación, nonce y sello de tiempo UTC | 5 pts | RF-17, RF-18 | RNF-22 | **RS-13** (`FCS_COP.1`), **RS-26** (`FIA_UAU.6`), **RS-43** (`FPT_STM.1`) |
| Evidencias de origen y recepción para los 5 eventos del happy path y verificación de firmas | 3 pts | RF-18, RF-19 | — | **RS-16** (`FCO_NRO.2`), **RS-17** (`FCO_NRR.2`), **RS-27** (`FDP_DAU.2`) |
| Pruebas automatizadas de firma y verificación + documentación del esquema de BD | 3 pts | RF-16 a RF-19 | RNF-07, RNF-08 | Pruebas de **RS-13**, **RS-16**, **RS-17**, **RS-26**, **RS-27** |

### 4.2. Mapa Exacto de Archivos Relacionados
* **Modelos Prisma:** `Certificate`, `SignatureEvidence` en `prisma/schema.prisma`.
* **Servicios de CA, Firma y Evidencias:** `src/modules/signatures/infrastructure/ca.service.ts`, `src/modules/signatures/application/signature.service.ts`, `src/modules/signatures/application/evidence.service.ts`, `src/modules/signatures/client/webcrypto-signer.ts`.
* **Rutas API:** `src/app/api/ca/issue-certificate/route.ts`, `src/app/api/contracts/[id]/sign/route.ts`, `src/app/api/contracts/[id]/verify-signatures/route.ts`.
* **Pruebas:** `src/modules/signatures/__tests__/signature.test.ts`.

### 4.3. Explicación para Defensa Individual
* **`generateKeyPairAndSignInBrowser()` en `webcrypto-signer.ts`:** Cumple **RS-10 (`FCS_CKM.1`)** y **RS-14 (`FCS_CKM.4`)** generando claves `ECDSA P-256` en el navegador (`window.crypto.subtle`), enviando solo la clave pública (`SPKI`) a la CA emisora y limpiando el material sensible en memoria tras firmar.
* **`CAService.issueUserCertificate()`:** Cumple **RF-16** y **RS-46 (`FMT_SMF.1`)** emitiendo certificados con serial único, vigencia de 1 año (**RS-42**) y firma de la CA Emisora de Interadds.
* **`SignatureService.signContract()`:** Exige re-autenticación con contraseña (**RS-26 / `FIA_UAU.6`**), adjunta un nonce único y sello de tiempo UTC del servidor (**RS-43 / `FPT_STM.1`**), verifica la firma criptográfica con `crypto.verify` (**RS-13 / `FCS_COP.1`**) y pasa el contrato a `FIRMADO_POR_UNA_PARTE` (1 firma) o `VIGENTE` (2 firmas — **RF-18**).
* **`EvidenceService.recordEventEvidence()` y `verifyAllContractEvidences()`:** Cumplen **RS-16 (`FCO_NRO.2` - Evidencia de origen)**, **RS-17 (`FCO_NRR.2` - Evidencia de recepción)** y **RS-27 (`FDP_DAU.2`)** para los 5 eventos del flujo feliz (firma, pago de anticipo, entrega de archivo, aprobación y pago de saldo).

---

## 5. Salma Morales — Chat y Entrega de Contenido (19 pts Web B1 | 11 pts Seg B1)

### 5.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Common Criteria (RS) en Código |
| :--- | :---: | :--- | :--- | :--- |
| Socket.IO en el servidor Node con handshake autenticado y sala privada por contrato tras pago de anticipo | 6 pts | RF-23 | RNF-04, RNF-05, RNF-10 | **RS-08** (`FIA_UID.2`), **RS-09** (`FIA_UAU.2`), **RS-18** (`FDP_ACC.1`), **RS-19** (`FDP_ACF.1`) |
| Historial de mensajes, indicador de conectados y sala general de dudas | 3 pts | RF-24, RF-25 | RNF-04 | **RS-43** (`FPT_STM.1`) |
| Saneamiento de mensajes y subida de archivos del entregable validando tipo, tamaño y hash SHA-256 | 5 pts | RF-26 | RNF-01 | **RS-16** (`FCO_NRO.2`), **RS-17** (`FCO_NRR.2`), **RS-44** (`FDP_IFC.1`), **RS-45** (`FDP_IFF.1`) |
| Notificaciones en tiempo real de los 5 hitos y política de avisos sin texto del contrato + pruebas/demo WS | 5 pts | RF-29 | RNF-04, RNF-07 | **RS-44** (`FDP_IFC.1`), **RS-45** (`FDP_IFF.1`) |

### 5.2. Mapa Exacto de Archivos Relacionados
* **Modelos Prisma:** `ChatRoom`, `ChatMessage`, `Deliverable` en `prisma/schema.prisma`.
* **Servidor Socket.IO y Servicios:** `src/modules/chat/infrastructure/socket.handler.ts`, `src/modules/chat/application/chat.service.ts`, `src/modules/chat/application/deliverable.service.ts`, `src/modules/chat/application/notification.service.ts`.
* **Rutas API:** `src/app/api/contracts/[id]/deliverables/route.ts`, `src/app/api/chat/[contractId]/messages/route.ts`.
* **Pruebas:** `src/modules/chat/__tests__/chat-security.test.ts`.

### 5.3. Explicación para Defensa Individual
* **Middleware `io.use(...)` en `socket.handler.ts`:** Cumple **RNF-04**, **RS-08** y **RS-09** validando la sesión en el handshake de Socket.IO antes de aceptar la conexión.
* **Evento `join:contract-room` en `socket.handler.ts`:** Cumple **RF-23**, **RS-18** y **RS-19** verificando en base de datos que el usuario sea `clientId` o `providerId` y que el estado del contrato sea al menos `ANTICIPO_PAGADO` (rechaza con error si el contrato sigue sin anticipo o si es un tercero).
* **`DeliverableService.uploadDeliverable()`:** Cumple **RF-26**, **RS-16** y **RS-17** validando MIME type permitido (`application/pdf`, `image/png`, `image/jpeg`, `video/mp4`, `application/zip`), tamaño máximo, calculando el `fileSha256`, guardando fuera de la carpeta pública y avanzando el contrato a `CONTENIDO_ENTREGADO`.
* **`NotificationService.notifyMilestone()`:** Cumple **RF-29**, **RS-44 (`FDP_IFC.1`)** y **RS-45 (`FDP_IFF.1`)** emitiendo avisos de los 5 hitos sin incluir jamás el texto del contrato (`contractText`) ni enlaces públicos directos.

---

## 6. Sebas Sarasti — Frontend y Presentación (25 pts Web B1)

### 6.1. Desglose de Entregables y Requisitos Cumplidos
| Entregable del Reparto | Puntos | RF Cumplidos | RNF Cumplidos | Controles de Seguridad Apoyados en UI |
| :--- | :---: | :--- | :--- | :--- |
| Layout general, navegación dinámica por rol y formularios con validación en cliente | 5 pts | RF-04, RF-05, RF-08, RF-09 | RNF-01, RNF-05 | **RS-06** (validación de clave en UI), **RS-38** (menú por rol) |
| Pantallas de catálogo con filtros, detalle, redirección tras login y CRUD de servicios del Proveedor | 5 pts | RF-01, RF-02, RF-03, RF-10, RF-11, RF-12, RF-13 | RNF-01, RNF-06 | Retorno seguro al servicio tras login (`returnUrl` interno) |
| Visor protegido del contrato con marca de agua dinámica (nombre, correo, fecha/hora) sin URL directa | 4 pts | RF-14, RF-15, RF-36, RF-37 | RNF-21 | **RF-37** (marca de agua disuasoria), **RS-18** |
| Interfaz de firma con WebCrypto en navegador y botones de pago con PayPal (anticipo y saldo) | 5 pts | RF-16 a RF-22, RF-28 | RNF-22, RNF-24 | Modal de re-autenticación (**RS-26**) previo a firmar y pagar |
| Interfaz de chat en tiempo real, subida/aprobación de entregables y campana de notificaciones | 4 pts | RF-23 a RF-27, RF-29 | RNF-04, RNF-05 | Escape en renderizado de mensajes y bloqueo visual según estado |
| Diagrama de arquitectura del monolito y guión de la demo de 15 minutos | 2 pts | Flujo completo | RNF-08, RNF-10 | — |

### 6.2. Mapa Exacto de Archivos Relacionados
* **Layout y Componentes Globales:** `src/app/layout.tsx`, `src/components/Navbar.tsx`, `src/components/NotificationBell.tsx`.
* **Vistas de Autenticación y Perfil:** `src/app/login/page.tsx`, `src/app/register/page.tsx`, `src/app/recover/page.tsx`, `src/app/profile/page.tsx`.
* **Vistas de Catálogo y Proveedor:** `src/app/page.tsx`, `src/app/services/[id]/page.tsx`, `src/app/provider/services/page.tsx`.
* **Visor Protegido, Firma, Pagos y Chat del Contrato:** `src/app/contracts/page.tsx`, `src/app/contracts/[id]/page.tsx`, `src/components/ContractWatermarkViewer.tsx`, `src/components/WebCryptoSignModal.tsx`, `src/components/PayPalCheckoutBox.tsx`, `src/components/ContractChatAndDeliverables.tsx`.

---

## 7. Guía de Ramas y Pull Requests por Integrante (`RNF-09`)

Para que el historial del repositorio refleje de forma transparente el trabajo individual de los 6 integrantes, cada miembro sube exclusivamente los archivos de su vertical en su Pull Request correspondiente:

1. **PR #1 y #2 — Mateo Quisilema (`feat/mateo-platform-base` y `feat/mateo-paypal-and-approval`):**
   - Archivos: `src/server.ts`, `prisma/schema.prisma`, `prisma/migrations/*`, `src/lib/*`, `.env.example`, `src/modules/payments/**`, `src/app/api/payments/**`, `src/app/api/contracts/[id]/approve-deliverable/route.ts`, `README.md`, `GUIA_EQUIPO_Y_BASE_B1.md`, `TRAZABILIDAD_EQUIPO_B1.md`.
2. **PR #3 — Sebas Ramos (`feat/sebas-ramos-auth`):**
   - Archivos: `src/modules/auth/**`, `src/middleware.ts`, `src/app/api/auth/**`, `src/app/api/profile/**`.
3. **PR #4 — Danna Morales (`feat/danna-catalog-and-contracts`):**
   - Archivos: `prisma/seed.ts`, `src/modules/contracts/**`, `src/app/api/services/**`, `src/app/api/contracts/route.ts`, `src/app/api/contracts/[id]/route.ts`.
4. **PR #5 — Domenica Cardenas (`feat/domenica-ca-and-signatures`):**
   - Archivos: `src/modules/signatures/**`, `src/app/api/ca/**`, `src/app/api/contracts/[id]/sign/route.ts`, `src/app/api/contracts/[id]/verify-signatures/route.ts`.
5. **PR #6 — Salma Morales (`feat/salma-chat-and-deliverables`):**
   - Archivos: `src/modules/chat/**`, `src/app/api/contracts/[id]/deliverables/route.ts`, `src/app/api/chat/**`.
6. **PR #7 — Sebas Sarasti (`feat/sebas-sarasti-frontend`):**
   - Archivos: `src/app/**/page.tsx`, `src/components/**`, `docs/arquitectura-b1.png`, `docs/guion-demo-15min.md`.