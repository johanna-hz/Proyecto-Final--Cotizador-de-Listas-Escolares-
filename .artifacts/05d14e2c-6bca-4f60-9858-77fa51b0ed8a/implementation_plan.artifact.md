# Cotizador de Listas Triates - Plan de Implementación

Desarrollo de una aplicación móvil en Flutter y Firebase para **Triates Papelería**, cubriendo la gestión completa desde la cotización hasta la entrega final y comprobante en PDF.

## User Review Required

> [!IMPORTANT]
> **Dependencias Externas**: Se agregarán paquetes oficiales de Flutter (`firebase_auth`, `cloud_firestore`, `pdf`, `printing`, `intl`, `provider`) para soportar Autenticación, Firestore en tiempo real y Generación de PDF.

> [!NOTE]
> **Seguridad (OWASP)**:
> - Validación robusta de entradas (prevención de inyección NoSQL / datos malformados en Firestore).
> - Manejo seguro de credenciales con Firebase Auth.
> - Reglas de seguridad recomendadas para Firestore.

## Open Questions

Ninguna por el momento. La arquitectura está alineada con los 5 módulos funcionales solicitados.

## Proposed Changes

### Dependencias y Configuración
#### [MODIFY] [pubspec.yaml](file:///C:/Users/her45/StudioProjects/finalproject/pubspec.yaml)
- Agregar `firebase_auth`, `cloud_firestore`, `pdf`, `printing`, `intl`, `provider`.

---

### Módulo de Autenticación y Base
#### [NEW] [auth_service.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/services/auth_service.dart)
- Servicio de Firebase Auth para inicio de sesión y registro de usuarios con correo y contraseña.

#### [NEW] [login_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/login_screen.dart)
- Pantalla de inicio de sesión con validaciones y diseño profesional UI/UX.

#### [NEW] [register_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/register_screen.dart)
- Pantalla de registro de nuevos usuarios.

---

### Catálogo de Artículos (Módulo 5)
#### [NEW] [article_model.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/models/article_model.dart)
- Modelo de datos para artículos escolares (nombre, gama económica/estándar, precios).

#### [NEW] [catalog_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/catalog_screen.dart)
- Pantalla para dar de alta, editar y actualizar precios de artículos escolares en Firestore.

---

### Gestión de Cotizaciones y Órdenes (Módulo 1)
#### [NEW] [quote_model.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/models/quote_model.dart)
- Modelo de cotización (cliente, alumno/grado, fecha entrega, items, subtotal, descuento, total, abono, saldo, estado de surtido).

#### [NEW] [quote_form_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/quote_form_screen.dart)
- Creación, edición y duplicado de cotizaciones con cálculo automático en tiempo real.

---

### Control de Abonos, Saldos y Surtido (Módulos 2 & 3)
#### [NEW] [dashboard_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/dashboard_screen.dart)
- Pantalla principal con lista de cotizaciones, filtros (Pendientes de surtir, Listas para entrega, etc.), indicadores visuales de pago (Sin abono, Con abono, Liquidado) y estado operativo.

#### [NEW] [quote_detail_screen.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/screens/quote_detail_screen.dart)
- Checklist operativo por artículo (surtido / pendiente), gestión de abonos y saldo restante.

---

### Generación y Envío de PDF (Módulo 4)
#### [NEW] [pdf_service.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/services/pdf_service.dart)
- Generación de comprobante PDF profesional con datos de Triates Papelería, cliente, tabla de productos, totales, abono y saldo.
- Integración con paquete `printing` para compartir/imprimir.

---

### Pantalla Principal (Router / Wrapper)
#### [MODIFY] [main.dart](file:///C:/Users/her45/StudioProjects/finalproject/lib/main.dart)
- Configuración principal, inicialización de Firebase y control de estado de autenticación para redirigir a Login o Dashboard.

## Verification Plan

### Automated Tests
- Ejecución de pruebas de widget básicas `flutter test`.

### Manual Verification
- Inicio de sesión y registro de usuario en simulador/dispositivo.
- Creación de artículos en el catálogo.
- Creación de una cotización con selección de gama (económica/estándar), cálculo automático, aplicación de descuentos.
- Registro de abonos y cálculo de saldo pendiente.
- Uso del checklist operativo de surtido y cambio de estados.
- Generación de comprobante en PDF y previsualización/compartición.
