# ObraDu - Frontend (App Móvil)

Repositorio del frontend de **ObraDu**, un sistema integral para la gestión de obras.
Esta aplicación móvil multiplataforma consume la API REST del backend para proporcionar a jefes de obra y empleados una interfaz limpia y eficiente desde sus dispositivos.

## Tecnologías Utilizadas

Este proyecto ha sido desarrollado siguiendo patrones de diseño modulares y asíncronos:

* **Framework:** [Flutter]
* **Lenguaje:** Dart
* **Consumo de API:** Paquete `http` nativo
* **Manejo de Estado:** `FutureBuilder` y `StatefulWidgets`
* **Almacenamiento Local:** `SharedPreferences` 

## Características Principales

* **Autenticación y Roles:** Inicio de sesión dinámico que adapta el menú y las vistas dependiendo de si el usuario es `JEFE` o `EMPLEADO`.
* **Panel de Control:** Estadísticas en tiempo real y barras de progreso visuales para las obras activas.
* **Gestión de Obras y Tareas:** Visualización detallada de proyectos, permitiendo marcar tareas como terminadas (empleados) o aprobarlas/deshacerlas (jefes).
* **Control de Inventario:** Visualización del stock global y envío directo de materiales a obras mediante diálogos controlados.
* **Gestión de Flota y Personal:** Listados optimizados de empleados y vehículos con sus estados actuales (ej. Disponible, En Taller).

## Instalación y Configuración Local

Sigue estos pasos para compilar y ejecutar la aplicación en tu entorno de desarrollo local:

### 1. Clonar el repositorio

#### - Clona el repositorio y accede a la carpeta
```bash
git clone https://github.com/angelmscode/ObraDu-Frontend.git
cd ObraDu-Frontend
```

### 2. Instalar las dependencias

#### - Descarga las dependencias con el siguiente comando:

```bash
flutter pub get
```


### 3. Configurar la conexión al Backend

#### - Abre el archivo lib/services/api_service.dart. Asegúrate de que la variable baseUrl apunte a la dirección donde se está ejecutando el backend.

```bash
static const String baseUrl = "http://10.0.2.2:8000"
```


### 4. Ejecutar la aplicación

#### - En la terminal estando en la carpeta "Obradu-Frontend" ejecuta este comando:

```bash
flutter run
```

