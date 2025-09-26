# 🛠️ Guía de Administración del Servidor

Este documento es el manual de operaciones para los administradores de Wetlands Valdivia. Contiene todos los procedimientos y comandos necesarios para la gestión, el mantenimiento y la solución de problemas del servidor.

---

## 1. Gestión de Jugadores

La gestión de jugadores se realiza a través de una base de datos **SQLite**, no de archivos de texto. Esto es debido a una configuración especial del servidor documentada en `NUCLEAR_CONFIG_OVERRIDE.md`.

**Ubicación de la base de datos:** `/config/.minetest/worlds/world/auth.sqlite` (dentro del contenedor).

### 1.1. Listar Todos los Jugadores Registrados

Para obtener una lista completa de todos los usuarios registrados, ejecuta el siguiente comando en la terminal del VPS, desde la carpeta raíz del proyecto (`/home/gabriel/Wetlands-Valdivia`):

```bash
docker-compose exec -T luanti-server sqlite3 /config/.minetest/worlds/world/auth.sqlite 'SELECT name FROM auth;'
```
Esto consultará la base de datos y devolverá una lista limpia de nombres de usuario.

### 1.2. Gestión de Privilegios (Línea de Comandos)

Aunque se pueden usar comandos en el juego como `/grant`, la gestión avanzada o de emergencia se debe hacer directamente en la base de datos.

#### Obtener el ID de un jugador:
```bash
docker-compose exec -T luanti-server sqlite3 /config/.minetest/worlds/world/auth.sqlite "SELECT id, name FROM auth WHERE name LIKE '%nombre_del_jugador%';"
```

#### Otorgar un privilegio a un jugador (usando su ID):
```bash
# Reemplaza 'ID_JUGADOR' y 'privilegio'
docker-compose exec -T luanti-server sqlite3 /config/.minetest/worlds/world/auth.sqlite "INSERT OR IGNORE INTO user_privileges (id, privilege) VALUES (ID_JUGADOR, 'privilegio');"
```
**Ejemplo (dar `fly` al jugador con ID 14):**
```bash
docker-compose exec -T luanti-server sqlite3 /config/.minetest/worlds/world/auth.sqlite "INSERT OR IGNORE INTO user_privileges (id, privilege) VALUES (14, 'fly');"
```

#### Revocar un privilegio:
```bash
# Reemplaza 'ID_JUGADOR' y 'privilegio'
docker-compose exec -T luanti-server sqlite3 /config/.minetest/worlds/world/auth.sqlite "DELETE FROM user_privileges WHERE id = ID_JUGADOR AND privilege = 'privilegio';"
```

### 1.3. Gestión de Privilegios (En el juego)

La forma más sencilla para tareas comunes sigue siendo a través de comandos en el chat del juego.

*   **Otorgar privilegio:** `/grant <jugador> <privilegio>`
*   **Revocar privilegio:** `/revoke <jugador> <privilegio>`
*   **Ver privilegios:** `/privs <jugador>`

**Privilegios Comunes:**
*   `creative`: Activa el modo creativo.
*   `fly`: Permite volar.
*   `fast`: Permite moverse rápido.
*   `noclip`: Permite atravesar paredes.
*   `teleport`: Permite usar el comando `/teleport`.
*   `server`: Acceso a todos los comandos de administrador.

---

## 2. Sistema de Backups y Recuperación

El servidor cuenta con un **sistema de backups automatizado** robusto y completamente funcional.

*   **Estado Actual:** ✅ **COMPLETAMENTE FUNCIONAL** (Actualizado Sept 2025)
*   **Frecuencia:** Se crea un backup completo del mundo **cada 6 horas**.
*   **Ubicación:** Los archivos `.tar.gz` se guardan en `server/backups/`.
*   **Retención:** Se conservan los 10 backups más recientes.
*   **Tamaño Típico:** ~43MB por backup comprimido.

> 📖 **Documentación Completa:** Para información detallada, troubleshooting avanzado y procedimientos de emergencia, consulta [`docs/BACKUP_SYSTEM_GUIDE.md`](BACKUP_SYSTEM_GUIDE.md).

### 2.1. Verificar el Estado de los Backups (Verificación Rápida)

Conéctate al VPS, navega a la carpeta del proyecto y ejecuta:
```bash
ls -lh server/backups/
```
Deberías ver una lista de backups, con el más reciente teniendo menos de 6 horas de antigüedad.

**Verificación de Contenedores:**
```bash
docker ps | grep wetlands-valdivia
```
Ambos contenedores (`wetlands-valdivia-server` y `wetlands-valdivia-backup`) deben aparecer como "Up".

### 2.2. Backup Manual de Emergencia

Si necesitas crear un backup inmediato:
```bash
docker exec -t wetlands-valdivia-backup sh /scripts/backup.sh
```

### 2.3. Procedimiento de Restauración (Básico)

1.  **Detén el servidor:** `docker stop wetlands-valdivia-server wetlands-valdivia-backup`
2.  **Respalda el mundo actual:** `mv server/worlds server/worlds_DAÑADO_$(date +%Y%m%d)`
3.  **Crea carpeta limpia:** `mkdir -p server/worlds`
4.  **Restaurar backup más reciente:** 
    ```bash
    LATEST_BACKUP=$(ls -t server/backups/wetlands_valdivia_backup_*.tar.gz | head -1)
    tar -xzf "$LATEST_BACKUP" -C server/worlds/
    ```
5.  **Reinicia servicios:** `docker start wetlands-valdivia-server && docker start wetlands-valdivia-backup`

### 2.4. Troubleshooting de Backups

**Problema Común: Backups no se crean automáticamente**

```bash
# Verificar logs del contenedor backup
docker logs wetlands-valdivia-backup --tail 20

# Test manual para verificar funcionamiento
docker exec -t wetlands-valdivia-backup sh /scripts/backup.sh
```

**Si el contenedor backup falla constantemente:**
1. El servidor Luanti SIEMPRE está seguro (el mundo persiste)
2. Los backups manuales siguen funcionando
3. Consulta la documentación completa en `docs/BACKUP_SYSTEM_GUIDE.md`

> ⚠️ **Nota Importante**: El sistema de backups fue completamente reparado en Septiembre 2025. Si experimentas problemas similares a "exit status 127" o contenedores reiniciándose, consulta el historial de soluciones en la documentación especializada.

---

## 3. Comandos de Administración Esenciales

Aquí tienes una lista consolidada de los comandos más útiles.

| Comando | Descripción | Ejemplo |
|---|---|---|
| `/teleport <jugador> <x,y,z>` | Teletransporta a un jugador a coordenadas. | `/tp gabo 0 100 0` |
| `/bring <jugador>` | Trae un jugador a tu posición. | `/bring pepito` |
| `/time <0-24000>` | Cambia la hora del servidor. | `/time 6000` (mediodía) |
| `/weather <clear/rain>` | Cambia el clima. | `/weather clear` |
| `/clearobjects` | Elimina todos los objetos sueltos (items en el suelo). Útil para reducir el lag. | `/clearobjects` |
| `/shutdown` | Apaga el servidor. | `/shutdown` |
| `/kick <jugador> [razón]` | Expulsa a un jugador. | `/kick troll_1 Por molestar` |
| `/ban <jugador>` | Banea permanentemente a un jugador. | `/ban troll_1` |
| `/unban <jugador>` | Desbanea a un jugador. | `/unban troll_1` |
| `/mute <jugador>` | Silencia a un jugador en el chat. | `/mute spammer` |

---

## 4. Solución de Problemas Comunes

### 4.1. Problema: Monstruos aparecen en el servidor

*   **Contexto Histórico:** En el pasado, VoxeLibre a veces ignoraba las configuraciones `peaceful_mode` o `mobs_spawn = false` en `luanti.conf`.
*   **Síntoma:** Aparecen Creepers, Zombies, etc., contradiciendo la filosofía del servidor.
*   **Solución Inmediata (Comandos en el juego):**
    1.  **Forzar el día:** `/time 6000` (reduce el spawn de monstruos).
    2.  **Eliminar entidades existentes:** `/clearobjects` (esto elimina mobs hostiles que ya hayan aparecido).
*   **Solución Permanente (Configuración):**
    La configuración correcta en `luanti.conf` para deshabilitar monstruos en VoxeLibre es una combinación de varias claves. Asegúrate de que las siguientes estén presentes y activadas:
    ```ini
    # Configuración Anti-Monstruos para VoxeLibre
    only_peaceful_mobs = true
    mobs_spawn = false
    mcl_mob_cap_hostile = 0
    mcl_mob_cap_monster = 0
    mcl_spawn_monsters = false
    enable_damage = false
    ```
    Si el problema persiste, puede ser necesario crear un mod simple que elimine activamente las entidades hostiles como un seguro adicional.
