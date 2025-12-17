import struct
import zlib

def create_png(width, height, pixels):
    def png_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
    
    png_data = b'\x89PNG\r\n\x1a\n'
    png_data += png_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    
    raw_data = b''
    for row in pixels:
        raw_data += b'\x00' + b''.join(struct.pack('BBBB', *pixel) for pixel in row)
    
    png_data += png_chunk(b'IDAT', zlib.compress(raw_data, 9))
    png_data += png_chunk(b'IEND', b'')
    
    return png_data

def create_circle_image(size, inner_color, outer_color, border_width=4):
    pixels = []
    center = size / 2
    radius = size / 2 - 2
    
    for y in range(size):
        row = []
        for x in range(size):
            dx = x - center
            dy = y - center
            distance = (dx*dx + dy*dy) ** 0.5
            
            if distance > radius:
                row.append((0, 0, 0, 0))
            elif distance > radius - border_width:
                row.append(outer_color)
            else:
                row.append(inner_color)
        pixels.append(row)
    
    return pixels

print("Creando imagen de la base del joystick...")
base_pixels = create_circle_image(200, (80, 80, 80, 100), (150, 150, 150, 150), 5)
with open('joystick_base.png', 'wb') as f:
    f.write(create_png(200, 200, base_pixels))

print("Creando imagen del stick del joystick...")
stick_pixels = create_circle_image(200, (200, 200, 200, 200), (255, 255, 255, 255), 4)
with open('joystick_stick.png', 'wb') as f:
    f.write(create_png(200, 200, stick_pixels))

print("¡Imágenes creadas exitosamente!")
