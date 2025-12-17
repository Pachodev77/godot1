# 🌅 Cómo Verificar que el Sistema Día/Noche Funciona

## ✅ Cambios Aplicados

1. **Niebla eliminada** - Ya no hay niebla en la escena
2. **Ciclo acelerado** - Ahora dura 60 segundos (1 minuto) en lugar de 4 minutos
3. **Empieza en medianoche** - Verás las estrellas inmediatamente al iniciar

## 🎮 Prueba Rápida

1. Abre Godot
2. Ejecuta la escena (F5)
3. **Deberías ver inmediatamente:**
   - Cielo oscuro (es medianoche)
   - Estrellas parpadeando en el cielo
   - Poca luz ambiental

4. **Espera 15 segundos y verás:**
   - El sol empezar a salir
   - Las estrellas desaparecer gradualmente
   - Colores cálidos del amanecer (naranjas/rojos)

5. **A los 30 segundos (mediodía):**
   - Sol en lo alto
   - Cielo azul brillante
   - Máxima iluminación

6. **A los 45 segundos (atardecer):**
   - Colores dorados/púrpuras
   - Sol bajando

7. **A los 60 segundos (medianoche de nuevo):**
   - El ciclo se repite

## 🔍 Verificación en el Editor

Si no ves nada:

1. Abre `escena/mapa_test.tscn` en Godot
2. En el árbol de escena, busca el nodo **DayNightSystem**
3. Si NO existe, haz lo siguiente:
   - Clic derecho en "Escena" → "Instance Child Scene"
   - Selecciona `escena/day_night_system.tscn`
   - Guarda (Ctrl+S)

4. Verifica que dentro de DayNightSystem haya:
   - DirectionalLight
   - WorldEnvironment
   - Stars

## 🐛 Si Aún No Funciona

Abre la consola de Godot (Output) y busca errores. Si hay errores, compártelos conmigo.

## ⚙️ Ajustes

Para hacer el ciclo más lento o rápido:
- Selecciona el nodo **DayNightSystem**
- Cambia **Cycle Duration**:
  - 30 = Ciclo muy rápido (30 segundos)
  - 60 = Ciclo rápido (1 minuto) - ACTUAL
  - 120 = Ciclo medio (2 minutos)
  - 240 = Ciclo lento (4 minutos)

Para empezar en otro momento:
- Cambia **Start Time**:
  - 0.0 = Medianoche (estrellas visibles)
  - 0.25 = Amanecer (6 AM)
  - 0.5 = Mediodía (12 PM)
  - 0.75 = Atardecer (6 PM)
