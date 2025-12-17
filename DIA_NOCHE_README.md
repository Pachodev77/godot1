# Sistema de Ciclo Día/Noche

## ✨ Características

Tu escena ahora tiene un sistema completo de ciclo día/noche con:

- **Amanecer** - Colores cálidos naranjas y rojos
- **Día** - Luz brillante y cielo azul
- **Atardecer** - Hermosos tonos dorados y púrpuras
- **Noche** - Cielo oscuro con estrellas parpadeantes

## 🎮 Archivos Creados

1. **`script/day_night_cycle.gd`** - Script principal que controla el ciclo
2. **`shaders/stars.shader`** - Shader para estrellas procedurales con parpadeo
3. **`materials/stars_material.tres`** - Material con el shader de estrellas
4. **`escena/mapa_test.tscn`** - Escena actualizada con el sistema

## ⚙️ Configuración

En el nodo `DayNightCycle` de tu escena puedes ajustar:

### Parámetros Exportados:
- **`cycle_duration`** (default: 240.0) - Duración del ciclo completo en segundos
  - 240 = 4 minutos por ciclo completo
  - Ajusta según prefieras ciclos más rápidos o lentos

- **`start_time`** (default: 0.25) - Hora de inicio (0.0 a 1.0)
  - 0.0 = Medianoche
  - 0.25 = Amanecer
  - 0.5 = Mediodía
  - 0.75 = Atardecer

## 🌟 Sistema de Estrellas

Las estrellas aparecen automáticamente durante la noche con:
- Parpadeo realista
- Diferentes colores (blancas, azuladas, amarillentas)
- Densidad y tamaño ajustables en el material

Para ajustar las estrellas, edita `materials/stars_material.tres`:
- **`star_density`** - Cantidad de estrellas (0.0 - 1.0)
- **`star_size`** - Tamaño de las estrellas
- **`twinkle_speed`** - Velocidad del parpadeo

## 🎨 Efectos Visuales

El sistema incluye:
- **Niebla atmosférica** que cambia con la hora del día
- **Sombras dinámicas** del sol
- **Iluminación ambiental** que se adapta
- **Transiciones suaves** entre diferentes momentos del día
- **SSAO** (Screen Space Ambient Occlusion) para mejor profundidad

## 🔧 Personalización Avanzada

### Cambiar Colores del Atardecer/Amanecer:
Edita `day_night_cycle.gd` en las funciones:
- `update_lighting()` - Colores de la luz del sol
- `update_sky_color()` - Colores del ambiente

### Ajustar Velocidad de Transiciones:
Modifica los rangos de tiempo en `update_sky_color()`:
```gdscript
# Amanecer: time_of_day entre 0.23 y 0.27
# Atardecer: time_of_day entre 0.73 y 0.77
```

## 🚀 Cómo Usar

1. Abre tu escena `mapa_test.tscn`
2. Ejecuta el juego
3. El ciclo comenzará automáticamente en el amanecer
4. Observa las transiciones suaves entre día y noche

¡Disfruta de tus hermosos atardeceres y noches estrelladas! 🌅✨🌙
