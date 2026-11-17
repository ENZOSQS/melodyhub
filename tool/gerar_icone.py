"""Gera o ícone do Melody Hub (Android) sem dependências externas.

Desenho: duas colcheias ligadas, douradas, sobre fundo ameixa escuro, com um
anel rosa fino. Cores de lib/theme/app_theme.dart. Tudo é desenhado com
funções de distância (SDF), então cada tamanho sai nítido e com anti-aliasing.

Uso (na raiz do projeto):  py -I tool/gerar_icone.py
Gera:
- android/app/src/main/res/mipmap-*/ic_launcher.png            (legado)
- android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (adaptativo)
- android/app/src/main/res/mipmap-*/ic_launcher_background.png (adaptativo)
- android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png (Android 13+)
- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
- assets/app_icon/melodyhub_icon_1024.png                       (divulgação)
"""
import math
import os
import struct
import zlib

RES = 'android/app/src/main/res'
DENSIDADES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

FUNDO_CENTRO = (0x3D, 0x2E, 0x37)
FUNDO_BORDA = (0x17, 0x13, 0x16)
OURO_CLARO = (0xF6, 0xD8, 0xA2)
OURO = (0xE9, 0xB9, 0x6E)
ROSA = (0xD6, 0xA0, 0xB2)


# ---------------------------------------------------------------- PNG
def salvar_png(caminho, largura, altura, pixels):
    """pixels: bytearray RGBA, linha a linha."""
    linhas = b''.join(
        b'\x00' + bytes(pixels[y * largura * 4:(y + 1) * largura * 4])
        for y in range(altura)
    )

    def bloco(tipo, dados):
        corpo = tipo + dados
        return (struct.pack('>I', len(dados)) + corpo
                + struct.pack('>I', zlib.crc32(corpo) & 0xFFFFFFFF))

    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    with open(caminho, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(bloco(b'IHDR', struct.pack('>IIBBBBB', largura, altura, 8, 6, 0, 0, 0)))
        f.write(bloco(b'IDAT', zlib.compress(linhas, 9)))
        f.write(bloco(b'IEND', b''))


# ---------------------------------------------------------------- SDF
def sdf_elipse(px, py, cx, cy, a, b, ang):
    c, s = math.cos(ang), math.sin(ang)
    dx, dy = px - cx, py - cy
    x, y = dx * c + dy * s, -dx * s + dy * c
    k = math.hypot(x / a, y / b)
    return (k - 1) * min(a, b)


def sdf_caixa(px, py, x0, y0, x1, y1):
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2, (y1 - y0) / 2
    dx, dy = abs(px - cx) - hx, abs(py - cy) - hy
    fora = math.hypot(max(dx, 0), max(dy, 0))
    return fora + min(max(dx, dy), 0)


def sdf_poligono(px, py, pts):
    """Polígono convexo em sentido horário (y para baixo)."""
    d = -1e9
    n = len(pts)
    for i in range(n):
        (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
        ex, ey = x1 - x0, y1 - y0
        L = math.hypot(ex, ey)
        nx, ny = ey / L, -ex / L  # normal para fora
        d = max(d, (px - x0) * nx + (py - y0) * ny)
    return d


def sdf_anel(px, py, cx, cy, r, espessura):
    return abs(math.hypot(px - cx, py - cy) - r) - espessura / 2


def sdf_quadrado_arredondado(px, py, raio):
    """Quadrado [0,1]² com cantos arredondados."""
    dx = abs(px - 0.5) - (0.5 - raio)
    dy = abs(py - 0.5) - (0.5 - raio)
    return math.hypot(max(dx, 0), max(dy, 0)) + min(max(dx, dy), 0) - raio


# Geometria das colcheias, em coordenadas da camada de frente (0..1),
# dentro da zona segura do ícone adaptativo (círculo de raio ~0,30).
CABECAS = [(0.405, 0.655), (0.615, 0.605)]
CAB_A, CAB_B, CAB_ANG = 0.078, 0.056, math.radians(-22)
HASTE_L = 0.026
TOPO = [0.335, 0.285]
VIGA = 0.062


NOTAS_ESCALA = 0.80  # mantém as notas por dentro do anel rosa


def sdf_notas(px, py):
    # Desenho centralizado: reduz em torno do centro do motivo (0,505; 0,50).
    px = 0.505 + (px - 0.5) / NOTAS_ESCALA
    py = 0.50 + (py - 0.5) / NOTAS_ESCALA
    return _sdf_notas(px, py) * NOTAS_ESCALA


def _sdf_notas(px, py):
    d = 1e9
    for (cx, cy), topo in zip(CABECAS, TOPO):
        d = min(d, sdf_elipse(px, py, cx, cy, CAB_A, CAB_B, CAB_ANG))
        hx = cx + CAB_A * 0.84
        # A haste começa dentro da viga, sem deixar degrau no topo.
        d = min(d, sdf_caixa(px, py, hx - HASTE_L, topo + VIGA * 0.5, hx, cy - 0.01))
    x0 = CABECAS[0][0] + CAB_A * 0.84 - HASTE_L
    x1 = CABECAS[1][0] + CAB_A * 0.84
    viga = [(x0, TOPO[0]), (x1, TOPO[1]), (x1, TOPO[1] + VIGA), (x0, TOPO[0] + VIGA)]
    return min(d, sdf_poligono(px, py, viga))


def sdf_anel_rosa(px, py):
    return sdf_anel(px, py, 0.5, 0.5, 0.285, 0.014)


# ---------------------------------------------------------------- cores
def misturar(c0, c1, t):
    t = min(max(t, 0.0), 1.0)
    return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))


def cor_fundo(px, py):
    d = math.hypot(px - 0.5, py - 0.42) / 0.75
    return misturar(FUNDO_CENTRO, FUNDO_BORDA, d)


def cor_ouro(py):
    return misturar(OURO_CLARO, OURO, (py - 0.28) / 0.45)


def cobertura(d, px_size):
    return min(max(0.5 - d / px_size, 0.0), 1.0)


def sobre(base, cor, alfa):
    """Compõe cor (alfa) sobre base RGBA (floats)."""
    r, g, b, a = base
    na = alfa + a * (1 - alfa)
    if na == 0:
        return (0, 0, 0, 0)
    mix = lambda c, bc: (c * alfa + bc * a * (1 - alfa)) / na
    return (mix(cor[0], r), mix(cor[1], g), mix(cor[2], b), na)


def renderizar(tamanho, amostra):
    px_size = 1 / tamanho
    out = bytearray(tamanho * tamanho * 4)
    for y in range(tamanho):
        for x in range(tamanho):
            r, g, b, a = amostra((x + 0.5) / tamanho, (y + 0.5) / tamanho, px_size)
            i = (y * tamanho + x) * 4
            out[i:i + 4] = bytes((round(r), round(g), round(b), round(a * 255)))
    return out


def camada_frente(px, py, ps, monocromatica=False, escala=1.0):
    # escala > 1 aproxima o desenho (usado no ícone legado).
    qx, qy = 0.5 + (px - 0.5) / escala, 0.5 + (py - 0.5) / escala
    qs = ps / escala
    cor = (0.0, 0.0, 0.0, 0.0)
    branco = (255, 255, 255)
    anel = cobertura(sdf_anel_rosa(qx, qy), qs)
    if anel > 0 and not monocromatica:
        cor = sobre(cor, ROSA, anel * 0.85)
    # Brilho suave atrás das notas.
    brilho = max(0.0, 1 - math.hypot(qx - 0.51, qy - 0.5) / 0.22) ** 2 * 0.18
    if brilho > 0 and not monocromatica:
        cor = sobre(cor, OURO, brilho)
    notas = cobertura(sdf_notas(qx, qy), qs)
    if notas > 0:
        cor = sobre(cor, branco if monocromatica else cor_ouro(qy), notas)
    return cor


def amostra_fundo(px, py, ps):
    return (*cor_fundo(px, py), 1.0)


def amostra_frente(px, py, ps):
    return camada_frente(px, py, ps)


def amostra_mono(px, py, ps):
    return camada_frente(px, py, ps, monocromatica=True)


def amostra_legado(px, py, ps):
    forma = cobertura(sdf_quadrado_arredondado(px, py, 0.22), ps)
    if forma == 0:
        return (0, 0, 0, 0)
    base = (*cor_fundo(px, py), 1.0)
    frente = camada_frente(px, py, ps, escala=1.32)
    if frente[3] > 0:
        base = sobre(base, frente[:3], frente[3])
    return (base[0], base[1], base[2], forma)


def main():
    for nome, fator in DENSIDADES.items():
        pasta = f'{RES}/mipmap-{nome}'
        legado = round(48 * fator)
        camada = round(108 * fator)
        salvar_png(f'{pasta}/ic_launcher.png', legado, legado,
                   renderizar(legado, amostra_legado))
        salvar_png(f'{pasta}/ic_launcher_foreground.png', camada, camada,
                   renderizar(camada, amostra_frente))
        salvar_png(f'{pasta}/ic_launcher_background.png', camada, camada,
                   renderizar(camada, amostra_fundo))
        salvar_png(f'{pasta}/ic_launcher_monochrome.png', camada, camada,
                   renderizar(camada, amostra_mono))
        print('ok', nome)

    os.makedirs(f'{RES}/mipmap-anydpi-v26', exist_ok=True)
    with open(f'{RES}/mipmap-anydpi-v26/ic_launcher.xml', 'w', encoding='utf-8', newline='\n') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
            '</adaptive-icon>\n'
        )

    salvar_png('assets/app_icon/melodyhub_icon_1024.png', 1024, 1024,
               renderizar(1024, amostra_legado))
    print('ok 1024')


if __name__ == '__main__':
    main()
