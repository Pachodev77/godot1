# 🌅 Sistema de Día y Noche - INSTRUCCIONES

## ✅ Archivos Creados

He creado el sistema de ciclo día/noche de una manera diferente para evitar conflictos:

1. **`escena/day_night_system.tscn`** - Escena independiente con todo el sistema
2. **`script/day_night_cycle.gd`** - Script de control del ciclo
3. **`shaders/stars.shader`** - Shader para las estrellas
4. **`materials/stars_material.tres`** - Material de estrellas
5. **`escena/mapa_test.tscn`** - ACTUALIZADO con la instancia del sistema

## 🎮 Cómo Usar

### Opción 1: Usar la escena actualizada (RECOMENDADO)
1. Abre Godot
2. Abre la escena `escena/mapa_test.tscn`
3. Presiona F5 para ejecutar
4. El ciclo día/noche debería funcionar automáticamente

### Opción 2: Si la Opción 1 no funciona (Agregar manualmente)
Si Godot sigue revirtiendo los cambios automáticamente:

1. Abre `escena/mapa_test.tscn` en el editor de Godot
2. En el árbol de escena, haz clic derecho en el nodo raíz "Escena"
3. Selecciona "Instance Child Scene"
4. Navega a `escena/day_night_system.tscn` y selecciónalo
5. Guarda la escena (Ctrl+S)
6. Ejecuta el juego (F5)

## 🔧 Configuración

Para ajustar el ciclo:

1. En el árbol de escena, selecciona el nodo **DayNightSystem**
2. En el Inspector verás:
   - **Cycle Duration**: Duración del ciclo completo en segundos (default: 240 = 4 minutos)
   - **Start Time**: Hora de inicio (0.0 a 1.0)
     - 0.0 = Medianoche
     - 0.25 = Amanecer (6 AM)
     - 0.5 = Mediodía (12 PM)
     - 0.75 = Atardecer (6 PM)

## 🌟 Características

- **Amanecer**: Colores cálidos naranjas/rojos
- **Día**: Luz solar brillante
- **Atardecer**: Tonos dorados y púrpuras
- **Noche**: Estrellas parpadeantes
- **Niebla atmosférica**: Se ajusta según la hora
- **Sombras dinámicas**: Del sol en movimiento

## 🐛 Solución de Problemas

### Si no ves el ciclo funcionando:
1. Verifica que el nodo **DayNightSystem** esté en la escena
2. Asegúrate de que no haya errores en la consola de Godot
3. Intenta cambiar `start_time` a 0.0 para ver las estrellas inmediatamente
4. Reduce `cycle_duration` a 60 para ver cambios más rápidos

### Si Godot revierte los cambios:
- Esto puede pasar si hay conflictos con el WorldEnvironment del bosque
- Usa la Opción 2 (agregar manualmente desde el editor)
- El sistema está diseñado como una escena independiente para evitar esto

## 📝 Notas Técnicas

El sistema usa:
- Un `DirectionalLight` que rota para simular el sol
- Un `WorldEnvironment` con cielo procedural
- Una esfera invertida con shader para las estrellas
- Transiciones suaves de colores y luz ambiental

¡Disfruta de tu ciclo día/noche! 🌅✨🌙
