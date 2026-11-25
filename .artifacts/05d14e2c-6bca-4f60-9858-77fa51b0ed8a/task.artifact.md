# Task List - Cotizador de Listas Triates

- [ ] **Fase 1: Configuración de Dependencias y Autenticación**
  - [ ] Actualizar pubspec.yaml con dependencias (firebase_auth, cloud_firestore, pdf, printing, intl, provider)
  - [ ] Implementar AuthService (Firebase Auth)
  - [ ] Implementar LoginScreen y RegisterScreen con validaciones y seguridad OWASP
  - [ ] Actualizar main.dart con flujo de autenticación y rutas

- [ ] **Fase 2: Catálogo Rápido de Artículos (Módulo 5)**
  - [ ] Crear ArticleModel
  - [ ] Implementar repositorio Firestore para artículos
  - [ ] Crear CatalogScreen (CRUD de útiles escolares, gama económica/estándar)

- [ ] **Fase 3: Gestión de Cotizaciones (Módulo 1)**
  - [ ] Crear QuoteModel (cliente, alumno, grado, fecha, items, subtotales, descuento, total, abonos, estado)
  - [ ] Crear QuoteFormScreen (armado dinámico, cálculo en tiempo real, edición y duplicado)

- [ ] **Fase 4: Control de Abonos, Saldos y Surtido (Módulos 2 & 3)**
  - [ ] Crear DashboardScreen con filtros y etiquetas visuales de pago (Sin abono, Con abono, Liquidado)
  - [ ] Crear QuoteDetailScreen con checklist de surtido por artículo y estados de flujo

- [ ] **Fase 5: Generación de PDF, Compartir y Pruebas (Módulo 4)**
  - [ ] Implementar PdfService para comprobantes y notas de apartado
  - [ ] Integrar botón de compartir PDF (WhatsApp/impresión)
  - [ ] Verificación general y pruebas de la aplicación
