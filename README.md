# Wordpress Roadmap Generator (o el nombre que elijas)

Un script de Bash (Shell) que clona el *frontend* de un sitio web WordPress y genera automáticamente una "Hoja de Ruta" (Roadmap) técnica para su recreación.

---

### El Problema que Resuelve

Como desarrollador o gestor web, a menudo nos enfrentamos a clientes que quieren migrar o recrear un sitio WordPress existente pero han perdido el acceso de administrador, o simplemente necesitamos estimar el esfuerzo de un rediseño. Auditar manualmente los *themes*, *plugins* y la estructura es un proceso lento y propenso a errores.

### La Solución 🚀

Este script automatiza todo el proceso:

1.  **Verifica** las dependencias necesarias (`httrack`, `wget`).
2.  **Clona** una versión navegable en local del sitio web.
3.  **Analiza** el código clonado para identificar el *theme*, los *plugins* principales (Ej. Elementor, WooCommerce), las tipografías y la estructura.
4.  **Genera** un archivo `HOJA_DE_RUTA_WORDPRESS.md` con un plan de acción completo, estimaciones y una lista de recursos necesarios.

### Tecnologías Utilizadas 🛠️

* **Bash (Shell Scripting)**
* `httrack` (Para el clonado recursivo)
* `wget` (Para metas y recursos adicionales)
* `grep`, `awk` (Para el análisis y parseo de datos - *aquí puedes poner las herramientas que uses para analizar*)

### Cómo Usarlo

1.  Dar permisos de ejecución:
    ```bash
    chmod +x tu-script.sh
    ```
2.  Ejecutar el script:
    ```bash
    ./tu-script.sh [https://www.ejemplo.com](https://www.ejemplo.com)
    ```
3.  Revisar los archivos generados:
    * `CLONACION_REPORTE.txt`
    * `HOJA_DE_RUTA_WORDPRESS.md`

### Mi Rol en este Proyecto

[cite_start]Este proyecto nació de mi experiencia profesional como gestor web freelance [cite: 135-137]. Quería automatizar el proceso de auditoría y planificación inicial de un proyecto, combinando mi pasión por **Linux** y el *scripting* con la necesidad de negocio de crear **estimaciones y planes de proyecto** de forma eficiente.
