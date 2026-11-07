# ПЕРВАЯ СЦЕНА

from pathlib import Path
from functools import lru_cache
import math
import re
import subprocess
import shutil

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_DIR = Path(__file__).resolve().parent
W, H = 1920, 1080
FPS = 24
DURATION = 16.4

SOURCE = [
    '#include <cstdio>',
    '#include <thread>',
    '',
    'int shared = 0;',
    '',
    'void writer() { shared = 42; }',
    'void reader() { std::printf("%d\\n", shared); }',
    '',
    'int main() {',
    '    std::thread t1(writer);',
    '    std::thread t2(reader);',
    '    t1.join();',
    '    t2.join();',
    '}',
]
INSTRUMENTED = [
    '#include <cstdio>',
    '#include <thread>',
    '',
    'int shared = 0;',
    '',
    'void writer() {',
    '    __tsan_write4(&shared);',
    '    shared = 42;',
    '}',
    '',
    'void reader() {',
    '    __tsan_read4(&shared);',
    '    std::printf("%d\\n", shared);',
    '}',
    'int main() {',
    '    std::thread t1(writer);',
    '    std::thread t2(reader);',
    '    t1.join();',
    '    t2.join();',
    '}',
]

FONT_PATHS = {
    'ui': ['/usr/share/fonts/opentype/inter/InterDisplay-Regular.otf',
           '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
           'C:/Windows/Fonts/segoeui.ttf'],
    'ui_bold': ['/usr/share/fonts/opentype/inter/InterDisplay-SemiBold.otf',
                '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
                'C:/Windows/Fonts/seguisb.ttf'],
    'code': ['/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf',
             '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
             'C:/Windows/Fonts/consola.ttf'],
    'code_bold': ['/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf',
                  '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf',
                  'C:/Windows/Fonts/consolab.ttf'],
}

@lru_cache(maxsize=None)
def font(kind, size):
    for p in FONT_PATHS[kind]:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

BG = '#05080C'
PANEL = '#10151C'
PANEL_INNER = '#0D1218'
WHITE = '#ECF2F8'
MUTED = '#8995A3'
CYAN = '#5FD3FF'
LEFT_OUTLINE = '#D5D9E4'
GREEN = '#91F18D'
YELLOW = '#FEDF28'

KEYWORD = '#57D9FA'
PREPROC = '#DF8FDB'
HEADER = '#DDA085'
FUNC = '#FFDF69'
DIGIT = '#C39DFB'
STRING = '#FFAB7A'
METHOD = '#66D6D3'
NAME = '#F4F5F9'

LEFT_BOX = (42, 190, 870, 746)
RIGHT_BOX = (925, 190, 1870, 843)
CMD_BOX = (48, 862, 866, 1018)


def blank():
    return Image.new('RGB', (W, H), BG)


def centered(draw, y, s, ft, color, cx=W // 2):
    bbox = draw.textbbox((0, 0), s, font=ft)
    draw.text((cx - (bbox[2] - bbox[0]) / 2, y), s, font=ft, fill=color)


def rectangle(draw, coords, radius, fill, border=None, borderw=1):
    draw.rounded_rectangle(coords, radius=radius, fill=fill,
                           outline=border, width=borderw)


def code_segments(s):
    if s.startswith('#include'):
        return [('#include', PREPROC), (' ', NAME), (s[len('#include '):], HEADER)]
    pattern = re.compile(
        r'"(?:\\.|[^"\\])*"|'
        r'\b(?:int|void)\b|'
        r'\b(?:writer|reader|main|__tsan_write4|__tsan_read4)\b|'
        r'\b(?:std|thread|printf)\b|'
        r'\b\d+\b|'
        r'[=]|'
        r'\s+|'
        r'.',
    )
    result = []
    for m in pattern.finditer(s):
        t = m.group(0)
        if t.startswith('"'):
            c = STRING 
        elif t in ('int', 'void'):
            c = KEYWORD
        elif t in ('writer', 'reader', 'main'):
            c = FUNC
        elif t in ('__tsan_write4', '__tsan_read4'):
            c = '#B8F28D'
        elif t in ('std', 'thread', 'printf'):
            c = METHOD
        elif t.isdecimal():
            c = DIGIT
        elif t == '=':
            c = '#ED84C8'
        else:
            c = NAME
        result.append((t, c))
    return result


def code_line(draw, x, y, line, ft, bold=False):
    xx = x
    for span, color in code_segments(line):
        draw.text((xx, y), span, font=ft, fill=color, stroke_width=0)
        xx += draw.textlength(span, font=ft)
    return xx


def fit_code_font(draw, lines, size, available_width):
    # На разных компьютерах шрифты отличаются по ширине. Подбираю размер по месту.
    while size >= 8:
        ft = font('code', size)
        widths = [sum(draw.textlength(span, font=ft)
                      for span, _ in code_segments(line)) for line in lines]
        if max(widths, default=0) <= available_width:
            return ft
        size -= 1
    raise ValueError('Текст не помещается в панель даже при минимальном размере шрифта.')


def code_panel(img, coords, label, code, instrumented=False):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = coords
    outline = GREEN if instrumented else LEFT_OUTLINE
    rectangle(d, coords, 20, PANEL, outline, 3)
    line_x = x0 + 67
    d.line((line_x, y0 + 22, line_x, y1 - 22), fill='#34404B', width=2)
    txt_x = x0 + 91
    ft = fit_code_font(d, code, 26 if not instrumented else 29, x1-16-txt_x)
    y_start = y0 + 29
    line_height = 35 if not instrumented else 30.4
    added = (6, 11) if instrumented else ()
    for i, s in enumerate(code):
        y = y_start + i * line_height
        if i in added:
            rectangle(d, (line_x + 5, round(y) - 3, x1 - 10, round(y) + 28),
                      2, '#185B2D')
            d.rectangle((line_x + 5, round(y) - 3, line_x + 39, round(y) + 28),
                        fill='#22783C')
            d.text((line_x + 14, y - 1), '+', font=font('code_bold', 28),
                   fill='#E9FFF1')
        ln = str(i + 1)
        d.text((line_x - 13 - d.textlength(ln, font=font('code', 24)), y + 2),
               ln, font=font('code', 24), fill=MUTED)
        end_x = code_line(d, txt_x, y, s, ft)
        if end_x > x1 - 8:
            raise ValueError(f'String overflows code box: {s!r} x={end_x:.1f}, max={x1-8}')
    centered(d, y0 - 68, label, font('ui', 33), WHITE, (x0 + x1) // 2)


def header(img):
    d = ImageDraw.Draw(img)
    centered(d, 26, 'Сборка с инструментацией', font('ui_bold', 75), '#81CFFF')


def command_box(img):
    d = ImageDraw.Draw(img)
    rectangle(d, CMD_BOX, 20, '#09212C', '#4BD5FF', 3)
    x0, y0, x1, y1 = CMD_BOX
    rectangle(d, (x0 + 15, y0 + 27, x1 - 15, y1 - 25), 12,
              '#10202C', '#295D76', 2)
    line1 = 'clang++ -std=c++17 -g -O1 \\'
    line2 = '-fsanitize=thread -pthread race.cpp -o race'
    ft = fit_code_font(d, [line1, line2], 29, x1-24-(x0+32))
    d.text((x0 + 32, y0 + 35), line1, font=ft,
           fill=WHITE)
    pos = x0 + 32
    for s, c in [('-fsanitize=thread', YELLOW),
                 (' -pthread race.cpp -o race', WHITE)]:
        d.text((pos, y0 + 78), s, font=ft, fill=c)
        pos += d.textlength(s, font=ft)
    if pos > x1 - 16:
        raise ValueError('Compile command out of box')


def bezier(points, count=100):
    (p0,p1,p2,p3) = points
    result=[]
    for i in range(count + 1):
        t = i/count
        u = 1-t
        result.append((
            u*u*u*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t*t*t*p3[0],
            u*u*u*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t*t*t*p3[1],
        ))
    return result

YELLOW_PATH = bezier([(355, 747), (360, 800), (308, 849), (230, 861)])
GREEN_PATH = bezier([(867, 939), (1000, 945), (1040, 881), (1122, 845)])


def arrow_layer(path, color, progress):
    overlay = Image.new('RGBA', (W, H), (0,0,0,0))
    count = max(2, min(len(path), int(1 + (len(path)-1)*progress)))
    pts = path[:count]
    trail = Image.new('RGBA', (W, H), (0,0,0,0))
    dt = ImageDraw.Draw(trail)
    rgb = tuple(bytes.fromhex(color.lstrip('#')))
    dt.line(pts, fill=(*rgb, 170), width=14, joint='curve')
    overlay = Image.alpha_composite(overlay, trail.filter(ImageFilter.GaussianBlur(13)))
    d = ImageDraw.Draw(overlay)
    d.line(pts, fill=(*rgb, 255), width=6, joint='curve')
    tip=pts[-1]
    prev=pts[max(0, len(pts)-5)]
    ang=math.atan2(tip[1]-prev[1],tip[0]-prev[0])
    wing=21
    side=0.54
    tri=[tip,
         (tip[0]-wing*math.cos(ang)+wing*side*math.sin(ang),
          tip[1]-wing*math.sin(ang)-wing*side*math.cos(ang)),
         (tip[0]-wing*math.cos(ang)-wing*side*math.sin(ang),
          tip[1]-wing*math.sin(ang)+wing*side*math.cos(ang))]
    d.polygon(tri, fill=(*rgb, 255))
    return overlay


def add_arrow(image, path, color, frac=1):
    return Image.alpha_composite(image.convert('RGBA'),
                                 arrow_layer(path, color, frac)).convert('RGB')


def to_cv(image):
    return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)


def ease(u):
    u = max(0.0, min(1.0, u))
    return u * u * (3 - 2 * u)


def tween(t, t0, t1):
    return ease((t - t0)/(t1-t0))


def blend(a, b, p):
    if p <= 0:
        return a
    if p >= 1:
        return b
    return cv2.addWeighted(a, 1-p, b, p, 0)


def compose_frames():
    scene_title=blank()
    header(scene_title)
    scene_left=scene_title.copy()
    code_panel(scene_left, LEFT_BOX, 'Исходный код (race.cpp)', SOURCE)
    scene_yellow=add_arrow(scene_left, YELLOW_PATH, YELLOW)
    scene_cmd=scene_yellow.copy()
    command_box(scene_cmd)
    scene_green=add_arrow(scene_cmd, GREEN_PATH, GREEN)
    scene_right=scene_green.copy()
    code_panel(scene_right, RIGHT_BOX, 'Инструментированный код', INSTRUMENTED, True)
    scene_pulse = scene_right.copy()
    dp=ImageDraw.Draw(scene_pulse, 'RGBA')
    x0, y0, x1, y1 = RIGHT_BOX
    for i in (6,11):
        y=y0+29+i*30.4
        dp.rounded_rectangle((x0+70, int(y-3), x1-10, int(y+28)),
                             radius=2, fill=(61,214,105,48))


    intro=blank()
    di=ImageDraw.Draw(intro)
    centered(di, 402, 'ThreadSanitizer', font('ui_bold', 118), '#F2F7FC')

    stepcount=35
    yellow_partial=[to_cv(add_arrow(scene_left, YELLOW_PATH, YELLOW,
                                    ease(i/(stepcount-1))))
                    for i in range(stepcount)]
    green_partial=[to_cv(add_arrow(scene_cmd, GREEN_PATH, GREEN,
                                   ease(i/(stepcount-1))))
                   for i in range(stepcount)]

    stages = dict(intro=to_cv(intro), title=to_cv(scene_title),
                  left=to_cv(scene_left), yellow=to_cv(scene_yellow),
                  cmd=to_cv(scene_cmd), green=to_cv(scene_green),
                  right=to_cv(scene_right), pulse=to_cv(scene_pulse))
    return stages, yellow_partial, green_partial, scene_right 


def frame_at(t, s, yellow_seq, green_seq):
    if t < 2.0:
        return s['intro']
    if t < 2.8:
        return blend(s['intro'], s['title'], tween(t, 2.0, 2.8))
    if t < 3.5:
        return s['title']
    if t < 4.9:
        return blend(s['title'], s['left'], tween(t, 3.5, 4.9))
    if t < 5.4:
        return s['left']
    if t < 6.35:
        i = int(tween(t, 5.4, 6.35)*(len(yellow_seq)-1))
        return yellow_seq[i]
    if t < 6.55:
        return s['yellow']
    if t < 7.75:
        return blend(s['yellow'], s['cmd'], tween(t, 6.55, 7.75))
    if t < 8.15:
        return s['cmd']
    if t < 9.15:
        i = int(tween(t, 8.15, 9.15)*(len(green_seq)-1))
        return green_seq[i]
    if t < 9.4:
        return s['green']
    if t < 10.85:
        return blend(s['green'], s['right'], tween(t, 9.4, 10.85))
    if t < 13.3:
        progress=(t - 10.85)
        pulsed = max(0, math.sin(progress * math.pi * 1.4))**2 * 0.45
        return blend(s['right'], s['pulse'], pulsed)
    return s['right']


def render():
    if shutil.which('ffmpeg') is None:
        raise RuntimeError('Не найден ffmpeg — установите его и повторите запуск.')
    stages, yellow_seq, green_seq, final_pil = compose_frames()


    out=OUT_DIR/'ThreadSanitizer_animation.mp4'
    cmd=['ffmpeg','-y', '-loglevel','error', '-f','rawvideo',
         '-vcodec','rawvideo', '-pix_fmt','bgr24','-s',f'{W}x{H}',
         '-r',str(FPS), '-i','pipe:0', '-an', '-c:v','libx264',
         '-preset','veryfast', '-crf','19', '-pix_fmt','yuv420p',
         '-movflags','+faststart', str(out)]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    total=int(round(FPS*DURATION))
    for idx in range(total):
        frame=frame_at(idx/FPS, stages, yellow_seq, green_seq)
        try:
            proc.stdin.write(frame.tobytes())
        except BrokenPipeError:
            raise RuntimeError('ffmpeg завершил работу с ошибкой')
        if idx % (FPS*3) == 0:
            print(f'Кадр {idx}/{total}', flush=True)
    proc.stdin.close()
    status=proc.wait()
    if status:
        raise RuntimeError(f'ffmpeg exited with {status}')
    print(f'Видео сохранено: {out} ({out.stat().st_size / 1048576:.1f} MB)')
    return out 


#ВТОРАЯ СЦЕНА
#aaaaaaaaaaaaaaaaaaaaaaaaaaaaa
from imageio_ffmpeg import get_ffmpeg_exe

# добавление шрифтов
FONT_PATHS['ui'] += ['/System/Library/Fonts/Supplemental/Arial.ttf',
                     '/Library/Fonts/Arial.ttf']
FONT_PATHS['ui_bold'] += ['/System/Library/Fonts/Supplemental/Arial Bold.ttf',
                          '/Library/Fonts/Arial Bold.ttf']
FONT_PATHS['code'] += ['/System/Library/Fonts/Menlo.ttc',
                       '/System/Library/Fonts/Supplemental/Courier New.ttf']
FONT_PATHS['code_bold'] += [
    '/System/Library/Fonts/Supplemental/Courier New Bold.ttf',
    '/System/Library/Fonts/Menlo.ttc']
font.cache_clear()

SCENE2_DURATION = 33.5
TRANSITION_DURATION = 0.9
SCHEME_SIZE = (1600, 1000)
SCHEME_BG = '#070B0E'
BLUE_TEXT = '#91D5ED'
GREY_TEXT = '#ACB3B9'
RED_TEXT = '#F27D8D'
GREEN_TEXT = '#ACD994'


def text_layer(x, y, text, size, color, bold=False, right=False):
    # Текст рисуется один раз на прозрачной подложке. y — нижняя линия букв.
    ft = font('ui_bold' if bold else 'ui', size)
    left, top, right_edge, bottom = ft.getbbox(text, anchor='ls')
    tile = Image.new('RGBA', (right_edge-left+4, bottom-top+4))
    d = ImageDraw.Draw(tile)
    d.text((2-left, 2-top), text, font=ft, fill=color, anchor='ls')
    if right:
        x -= ft.getlength(text)
    return tile, round(x+left-2), y+top-2


def block_layer(x, y, width, text, green=False):
    # Плашки чтения и записи одинаковые, для join зелёный цвет
    height = 56 if green else 50
    fill = '#203E2D' if green else '#294F61'
    color = GREEN_TEXT if green else BLUE_TEXT
    ft = font('code' if green else 'ui', 27 if green else 25)
    tile = Image.new('RGBA', (width+1, height+1))
    d = ImageDraw.Draw(tile)
    d.rounded_rectangle((0, 0, width, height), radius=8, fill=fill)
    d.text((width/2, height/2), text, font=ft, fill=color, anchor='mm')
    return tile, x, y


def make_scene2_layers():
    # надписи и плашки из второй схемы
    layers = {}
    layers['title'] = text_layer(60, 64, 'Пример ошибки: race condition', 38, BLUE_TEXT)
    layers['error'] = text_layer(60, 184,
        'Ошибка: запускаем оба потока — гонка данных', 28, RED_TEXT, bold=True)
    layers['time1'] = text_layer(1356, 184, 'Время', 22, GREY_TEXT, right=True)
    layers['writer1'] = text_layer(60, 287, 'T1 · writer()', 27, BLUE_TEXT, bold=True)
    layers['reader1'] = text_layer(60, 403, 'T2 · reader()', 27, BLUE_TEXT, bold=True)
    layers['read1'] = block_layer(490, 370, 190, 'чтение')
    layers['write1'] = block_layer(730, 254, 230, 'запись 42')
    layers['note'] = text_layer(840, 404,
        'Порядок записи и чтения не задан', 24, RED_TEXT)
    layers['divider'] = (Image.new('RGBA', (1481, 2), '#394247'), 60, 529)
    layers['correct'] = text_layer(60, 588,
        'Правильная реализация: завершаем T1, затем запускаем T2',
        28, GREEN_TEXT, bold=True)
    layers['time2'] = text_layer(1356, 631, 'Время', 22, GREY_TEXT, right=True)
    layers['writer2'] = text_layer(60, 711, 'T1 · writer()', 27, BLUE_TEXT, bold=True)
    layers['write2'] = block_layer(588, 678, 316, 'запись 42')
    layers['end'] = text_layer(924, 650, 'конец T1', 21, GREY_TEXT, right=True)
    layers['wait'] = text_layer(300, 792, 'main ждёт завершения T1', 24, GREY_TEXT)
    layers['join'] = block_layer(955, 758, 210, 't1.join()', green=True)
    layers['start'] = text_layer(1180, 846, 'запуск T2', 22, GREEN_TEXT)
    layers['reader2'] = text_layer(60, 906, 'T2 · reader()', 27, BLUE_TEXT, bold=True)
    layers['read2'] = block_layer(1200, 873, 320, 'чтение 42')
    return layers


def fade_in(canvas, layer, t, start, duration=0.9):
    # Чем ближе к концу интервала, тем меньше прозрачность.
    p = tween(t, start, start+duration)
    if p <= 0:
        return
    tile, x, y = layer
    if p < 1:
        tile = tile.copy()
        alpha = tile.getchannel('A')
        tile.putalpha(alpha.point([round(i*p) for i in range(256)]))
    canvas.paste(tile, (x, y), tile)


def timeline(canvas, x, y, width, t, start, duration=1.6):
    # Полоса постепенно растёт слева направо.
    p = tween(t, start, start+duration)
    if p <= 0:
        return
    end = x + round(width*p)
    d = ImageDraw.Draw(canvas)
    d.rectangle((x, y, end, y+70), fill='#132733')
    d.line((x, y, end, y), fill='#75B8D0', width=2)
    d.line((x, y+70, end, y+70), fill='#75B8D0', width=2)


def draw_path(canvas, points, color, t, start, duration=1.0, arrow=False):
    # Линия проходит по точкам по порядку, а не возникает целиком.
    p = tween(t, start, start+duration)
    if p <= 0:
        return
    lengths = [math.dist(a, b) for a, b in zip(points, points[1:])]
    remaining = sum(lengths)*p
    visible = [points[0]]
    for a, b, length in zip(points, points[1:], lengths):
        part = min(1.0, remaining/length)
        visible.append((a[0]+(b[0]-a[0])*part, a[1]+(b[1]-a[1])*part))
        remaining -= length
        if remaining <= 0:
            break
    d = ImageDraw.Draw(canvas)
    d.line(visible, fill=color, width=3, joint='curve')
    if arrow:
        # Наконечник двигается вместе с концом линии.
        ax, ay = visible[-2]
        bx, by = visible[-1]
        angle = math.atan2(by-ay, bx-ax)
        side1 = (bx-12*math.cos(angle)+7*math.sin(angle),
                 by-12*math.sin(angle)-7*math.cos(angle))
        side2 = (bx-12*math.cos(angle)-7*math.sin(angle),
                 by-12*math.sin(angle)+7*math.cos(angle))
        d.line([side1, (bx, by), side2], fill=color, width=3)


def scene2_frame(t, layers):
    # t отсчитывается от начала второй сцены
    canvas = Image.new('RGB', SCHEME_SIZE, SCHEME_BG)

    # Сначала заголовок, затем название ошибочного варианта и шкала времени
    fade_in(canvas, layers['title'], t, 0.0, 1.2)
    fade_in(canvas, layers['error'], t, 1.8)
    fade_in(canvas, layers['time1'], t, 1.8)
    draw_path(canvas, [(1372, 176), (1540, 176)], GREY_TEXT, t, 1.8, arrow=True)

    # Обе полосы начинаются одновременно
    fade_in(canvas, layers['writer1'], t, 3.1)
    fade_in(canvas, layers['reader1'], t, 3.1)
    timeline(canvas, 300, 244, 700, t, 3.1)
    timeline(canvas, 300, 360, 1240, t, 3.1)

    # сначала чтение, потом запись
    fade_in(canvas, layers['read1'], t, 5.3)
    fade_in(canvas, layers['write1'], t, 8.1)
    fade_in(canvas, layers['note'], t, 10.6, 1.1)

    # время посмотреть на ошибку и открытие правильной вариации
    fade_in(canvas, layers['divider'], t, 14.4)
    fade_in(canvas, layers['correct'], t, 15.0, 1.1)
    fade_in(canvas, layers['time2'], t, 15.0)
    draw_path(canvas, [(1372, 623), (1540, 623)], GREY_TEXT, t, 15.0, arrow=True)

    # Сначала работает T1 и записывает 42
    fade_in(canvas, layers['writer2'], t, 17.0)
    timeline(canvas, 300, 668, 624, t, 17.0)
    fade_in(canvas, layers['write2'], t, 19.0)
    fade_in(canvas, layers['end'], t, 20.5)
    fade_in(canvas, layers['wait'], t, 20.5)

    # main дожидается завершения T1, до этого T2 ещё не появляется
    draw_path(canvas, [(924, 703), (1060, 703), (1060, 758)],
              GREEN_TEXT, t, 21.5, 0.9)
    fade_in(canvas, layers['join'], t, 22.4, 0.8)
    draw_path(canvas, [(1060, 814), (1060, 898), (1180, 898)],
              GREEN_TEXT, t, 23.6, 1.0, arrow=True)

    # После join запускается T2, теперь он читает уже записанное 42
    fade_in(canvas, layers['start'], t, 24.6, 0.7)
    fade_in(canvas, layers['reader2'], t, 24.6, 0.7)
    timeline(canvas, 1180, 863, 360, t, 25.3, 1.5)
    fade_in(canvas, layers['read2'], t, 27.2, 1.0)

    
    canvas = canvas.resize((1728, 1080), Image.Resampling.LANCZOS)
    frame = Image.new('RGB', (W, H), SCHEME_BG)
    frame.paste(canvas, (96, 0))
    return to_cv(frame)


def render_full():
    # функция запускается вместо render() и записывает сразу обе сцены.
    cv2.setNumThreads(1)
    stages, yellow_seq, green_seq, _ = compose_frames()
    layers = make_scene2_layers()

    out = OUT_DIR / 'ThreadSanitizer_full.mp4'
    temporary = OUT_DIR / 'ThreadSanitizer_rendering.mp4'
    # FFmpeg берётся из заранее установленного Python-пакета
    cmd = [get_ffmpeg_exe(), '-y', '-loglevel', 'error',
           '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-s', f'{W}x{H}',
           '-r', str(FPS), '-i', 'pipe:0', '-an', '-c:v', 'libx264',
           '-preset', 'veryfast', '-crf', '19', '-threads', '4',
           '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(temporary)]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    try:
        print('Сцена 1/2: сборка с инструментацией', flush=True)
        for i in range(round(DURATION*FPS)):
            frame = frame_at(i/FPS, stages, yellow_seq, green_seq)
            proc.stdin.write(frame.tobytes())

        # Плавное исчезновение первой сцены перед появлением второй
        last_frame = frame_at(DURATION, stages, yellow_seq, green_seq)
        next_frame = scene2_frame(0.0, layers)
        steps = round(TRANSITION_DURATION*FPS)
        for i in range(steps):
            frame = blend(last_frame, next_frame, ease((i+1)/steps))
            proc.stdin.write(frame.tobytes())

        print('Сцена 2/2: ошибочный и правильный порядок', flush=True)
        for i in range(round(SCENE2_DURATION*FPS)):
            frame = scene2_frame(i/FPS, layers)
            proc.stdin.write(frame.tobytes())
            if i % (FPS*5) == 0:
                print(f'Вторая сцена: {i/FPS:.0f}/{SCENE2_DURATION} с', flush=True)
    except BrokenPipeError:
        raise RuntimeError('FFmpeg прервал запись видео') from None
    finally:
        proc.stdin.close()
        status = proc.wait()
    if status != 0:
        raise RuntimeError(f'Видео не собрано')
    temporary.replace(out)
    print(f'Готово: {out}', flush=True)
    return out


if __name__ == '__main__':
    render_full()
