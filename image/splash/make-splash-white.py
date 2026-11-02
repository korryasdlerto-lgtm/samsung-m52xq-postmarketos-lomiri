#!/usr/bin/env python3
# Заставка Ubuntu Touch для m52xq (Plymouth-тема m52xq-ubuntu-touch), стиль «всё белое».
#   make-splash-white.py preview <каталог>   — лист превью (ряд «как сейчас» + варианты) без установки
#   make-splash-white.py theme <вариант> <каталог темы>   — картинки темы (background/logo/dot-on/dot-off)
# Раскладка — как в m52xq-ubuntu-touch.script: логотип 62 % ширины по центру, пять точек под ним (шаг 4,5 % ширины),
# яркая точка бежит слева направо. Всё переднего плана — чисто белое (логотип «ubuntu» + круг друзей + «touch», точки,
# сообщения Plymouth); выключенная точка — белая с прозрачностью.
import math, sys
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 2400
F = '/usr/share/fonts/truetype/ubuntu/'

# варианты фона
BACKGROUNDS = {
    # как сейчас: фиолетовый (слева/сверху) -> розовый (справа/снизу) + светлые грани
    'pink': ((178, 28, 182), (236, 20, 140), True),
    # классический «аубергин» Ubuntu: тёмно-фиолетовый -> оранжево-фиолетовый снизу
    'aubergine': ((44, 0, 30), (119, 33, 111), True),
}


THEME_BG = '/home/sasha/Templates/майнлайн/убунтутач24/003/build/splash/theme/m52xq-ubuntu-touch/background.png'


def background(kind='current', w=W, h=H):
    # ФОН НЕ ТРОГАЕМ: берётся готовый background.png текущей темы
    if kind == 'current':
        return Image.open(THEME_BG).convert('RGB')
    a, b, facets = BACKGROUNDS[kind]
    bg = Image.new('RGB', (w, h))
    px = bg.load()
    for y in range(h):
        for x in range(w):
            t = min(1.0, max(0.0, (x / w) * 0.55 + (y / h) * 0.45))
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    if facets:
        fac = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(fac)
        d.polygon([(0, 0), (w * 0.62, 0), (0, h * 0.42)], fill=(255, 255, 255, 14))
        d.polygon([(w, h * 0.30), (w, h), (w * 0.25, h)], fill=(255, 255, 255, 12))
        d.polygon([(w * 0.35, h * 0.55), (w, h * 0.20), (w, h * 0.62)], fill=(0, 0, 0, 22))
        bg = Image.alpha_composite(bg.convert('RGBA'), fac).convert('RGB')
    return bg


def logo_image(left_word=None, sub_text='touch', after_word=None):
    lw, lh = 680, 260
    logo = Image.new('RGBA', (lw * 2, lh * 2), (0, 0, 0, 0))   # 2x для гладких краёв
    d = ImageDraw.Draw(logo)
    fu = ImageFont.truetype(F + 'Ubuntu-M.ttf', 300)
    ft = ImageFont.truetype(F + 'Ubuntu-R.ttf', 140)
    d.text((10, 0), 'ubuntu', font=fu, fill='white')
    uw = d.textsize('ubuntu', font=fu)[0]
    cx, cy, r = 10 + uw + 50, 95, 40
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline='white', width=12)
    for k in range(3):
        ang = math.radians(-90 + 120 * k + 30)
        hx, hy = cx + r * math.cos(ang), cy + r * math.sin(ang)
        d.ellipse((hx - 15, hy - 15, hx + 15, hy + 15), fill='white')
    tw = d.textsize(sub_text, font=ft)[0]
    d.text((10 + uw - tw + 10, 270), sub_text, font=ft, fill='white')
    pad_left = 0
    bb_old = logo.getbbox()                          # границы без дописанного слова
    if after_word:  # слово справа от «touch» (за правым краем «ubuntu»)
        sx = 10 + uw - tw + 10 + tw + 40
        d.text((sx, 270), after_word, font=ft, fill='white')
        pad_left = max(0, logo.getbbox()[2] - bb_old[2])   # на сколько вправо выросла надпись: столько же добавим слева
    if left_word:   # слово у «touch»: слева, на той же строке, выровнено по левому краю «ubuntu»
        d.text((14, 270), left_word, font=ImageFont.truetype(F + 'Ubuntu-M.ttf', 140), fill='white')
    logo = logo.crop(logo.getbbox())
    if pad_left:
        big = Image.new('RGBA', (logo.width + pad_left, logo.height), (0, 0, 0, 0))
        big.alpha_composite(logo, (pad_left, 0))
        logo = big
    return logo.resize((logo.width // 2, logo.height // 2), Image.LANCZOS)


def text_logo(main, sub=None, size=300, sub_size=140):
    """Белая надпись в стиле логотипа Ubuntu Touch: крупное слово шрифтом Ubuntu Medium и (необязательно) малая подпись
    шрифтом Ubuntu Regular под правым краем. Без круга друзей (он принадлежит Ubuntu)."""
    fu = ImageFont.truetype(F + 'Ubuntu-M.ttf', size)
    ft = ImageFont.truetype(F + 'Ubuntu-R.ttf', sub_size)
    tmp = Image.new('RGBA', (4000, 800), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    d.text((10, 0), main, font=fu, fill='white')
    mw = d.textsize(main, font=fu)[0]
    if sub:
        sw = d.textsize(sub, font=ft)[0]
        d.text((10 + mw - sw + 10, int(size * 0.9)), sub, font=ft, fill='white')
    tmp = tmp.crop(tmp.getbbox())
    return tmp.resize((tmp.width // 2, tmp.height // 2), Image.LANCZOS) if False else tmp


def dot_image(on):
    # выключенная точка — белая, прозрачность 38 %; включённая — чисто белая, чуть больше
    rr, col = (11, (255, 255, 255, 255)) if on else (9, (255, 255, 255, 97))
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((16 - rr, 16 - rr, 16 + rr, 16 + rr), fill=col)
    return im


def old_dot(on):
    rr, col = (11, (255, 255, 255, 255)) if on else (9, (255, 190, 120, 150))
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((16 - rr, 16 - rr, 16 + rr, 16 + rr), fill=col)
    return im


def caption(text, size=64, weight='M'):
    f = ImageFont.truetype(F + 'Ubuntu-%s.ttf' % weight, size)
    tmp = Image.new('RGBA', (2400, 200), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    d.text((10, 10), text, font=f, fill='white')
    return tmp.crop(tmp.getbbox())


def pm_logo(size=900):
    """логотип postmarketOS (белый, монохромный): рисуется по SVG /usr/share/pixmaps/postmarketos-logo-monochrome.svg —
    три одинаковых многоугольника с поворотами; координаты SVG 100x100 (ось Y вниз)"""
    poly = [(29.7, 17.5), (25.9, 27.8), (15.0, 26.0), (0.0, 0.0), (65.0, 0.0), (58.0, 8.5), (65.0, 17.0), (29.8, 17.0)]
    def mat(t=(0, 0), rot=0.0):
        a = math.radians(rot); c, s_ = math.cos(a), math.sin(a)
        return [[c, -s_, t[0]], [s_, c, t[1]], [0, 0, 1]]
    def mul(A, B):
        return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    base = mul(mul(mat((100, 100)), mat((0, 0), 180)), mat((0, 6.698729810778069)))
    copies = [mat(), mul(mat((100, 0)), mat((0, 0), 120)), mul(mat((50, 86.60254037844386)), mat((0, 0), 240))]
    k = size / 100.0
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for cp in copies:
        M = mul(base, cp)
        pts = [((M[0][0] * x + M[0][1] * y + M[0][2]) * k, (M[1][0] * x + M[1][1] * y + M[1][2]) * k) for x, y in poly]
        d.polygon(pts, fill=(255, 255, 255, 255))
    return img.crop(img.getbbox())


def caption2(lines, size=64, weight='M', gap_px=18):
    """несколько строк по центру, одинаковым шрифтом (например, postmarketOS / Lomiri)"""
    ims = [caption(t, size, weight) for t in lines]
    wmax = max(i.width for i in ims)
    out = Image.new('RGBA', (wmax, sum(i.height for i in ims) + gap_px * (len(ims) - 1)), (0, 0, 0, 0))
    y = 0
    for i in ims:
        out.alpha_composite(i, ((wmax - i.width) // 2, y)); y += i.height + gap_px
    return out


def frame_cap(bg, logo, cap, where, dot_fn, bright, w=W, h=H, ref_w=None, cap_w=0.50, cap_gap=0.035):
    """логотип остаётся, надпись добавляется над логотипом (where='above') или между логотипом и точками ('below')"""
    img = bg.convert('RGBA').resize((w, h), Image.LANCZOS)
    k = (w * 0.62) / (ref_w or logo.width)
    lg = logo.resize((int(logo.width * k), int(logo.height * k)), Image.LANCZOS)
    ly = h / 2 - lg.height / 2
    img.alpha_composite(lg, (int(w / 2 - lg.width / 2), int(ly)))
    ck = (w * cap_w) / cap.width
    cp = cap.resize((int(cap.width * ck), int(cap.height * ck)), Image.LANCZOS)
    if where == 'above':
        cy = ly - cp.height - h * cap_gap
        dy = ly + lg.height + h * 0.03
    else:
        cy = ly + lg.height + h * 0.025
        dy = cy + cp.height + h * 0.03
    img.alpha_composite(cp, (int(w / 2 - cp.width / 2), int(cy)))
    step = w * 0.045
    for i in range(5):
        d = dot_fn(i == bright)
        img.alpha_composite(d, (int(w / 2 + (i - 2) * step - d.width / 2), int(dy)))
    return img.convert('RGB')


def frame(bg, logo, dot_fn, bright, w=W, h=H):
    """кадр заставки в натуральный размер с расчётом как в Plymouth-скрипте"""
    img = bg.convert('RGBA').resize((w, h), Image.LANCZOS)
    k = (w * 0.62) / logo.width
    lg = logo.resize((int(logo.width * k), int(logo.height * k)), Image.LANCZOS)
    ly = h / 2 - lg.height / 2
    img.alpha_composite(lg, (int(w / 2 - lg.width / 2), int(ly)))
    step = w * 0.045
    dy = ly + lg.height + h * 0.03
    for i in range(5):
        d = dot_fn(i == bright)
        img.alpha_composite(d, (int(w / 2 + (i - 2) * step - d.width / 2), int(dy)))
    return img.convert('RGB')


def preview(outdir):
    bg = background()
    ref = logo_image().width
    logo = logo_image(after_word='style')
    sc = 0.22
    fw, fh = int(W * sc), int(H * sc)
    gap, label_h = 18, 40
    txt = caption2(['postmarketOS', 'Lomiri'], size=96, weight='B', gap_px=26)
    # логотип pmOS крупно над надписью (ширина = 30 % ширины текста)
    pm = pm_logo(); pk = (txt.width * 0.30) / pm.width
    pm = pm.resize((int(pm.width * pk), int(pm.height * pk)), Image.LANCZOS)
    cap = Image.new('RGBA', (txt.width, pm.height + 40 + txt.height), (0, 0, 0, 0))
    cap.alpha_composite(pm, ((txt.width - pm.width) // 2, 0)); cap.alpha_composite(txt, (0, pm.height + 40))
    cap_k = 1.0
    rows = [('логотип pmOS над «postmarketOS / Lomiri» (зазор 11 % высоты)', lambda b: frame_cap(bg, logo, cap, 'above', dot_image, b, ref_w=ref, cap_w=0.80 * cap_k, cap_gap=0.11))]
    sheet = Image.new('RGB', (3 * fw + 4 * gap, len(rows) * (fh + label_h + gap) + gap), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(F + 'Ubuntu-R.ttf', 22)
    for r, (name, fn) in enumerate(rows):
        y = gap + r * (fh + label_h + gap)
        d.text((gap, y + 6), name, font=font, fill=(235, 235, 235))
        for c, bright in enumerate((0, 2, 4)):
            sheet.paste(fn(bright).resize((fw, fh), Image.LANCZOS), (gap + c * (fw + gap), y + label_h))
    sheet.save(outdir + '/splash-preview.png', optimize=True)
    rows[0][1](2).save(outdir + '/splash-big-full.png', optimize=True)
    print('превью:', outdir)


def theme(kind, outdir):
    # background.png НЕ перезаписывается
    logo_image().save(outdir + '/logo.png', optimize=True)
    dot_image(False).save(outdir + '/dot-off.png')
    dot_image(True).save(outdir + '/dot-on.png')
    print('тема:', kind, '->', outdir)


def caption_block():
    """надпись: логотип pmOS над строками «postmarketOS» / «Lomiri» (Ubuntu Bold), белая"""
    txt = caption2(['postmarketOS', 'Lomiri'], size=96, weight='B', gap_px=26)
    pm = pm_logo(); pk = (txt.width * 0.30) / pm.width
    pm = pm.resize((int(pm.width * pk), int(pm.height * pk)), Image.LANCZOS)
    cap = Image.new('RGBA', (txt.width, pm.height + 40 + txt.height), (0, 0, 0, 0))
    cap.alpha_composite(pm, ((txt.width - pm.width) // 2, 0)); cap.alpha_composite(txt, (0, pm.height + 40))
    return cap


def stage(src, outdir):
    """src — тема, снятая с телефона (background.png, logo.png, dot-*.png, *.script, *.plymouth); фон и скрипт берутся оттуда"""
    import shutil, os
    os.makedirs(outdir, exist_ok=True)
    shutil.copy(src + '/background.png', outdir + '/background.png')          # ФОН НЕ ТРОГАЕМ
    ref_w = logo_image().width
    logo_image(after_word='style').save(outdir + '/logo.png', optimize=True)
    dot_image(False).save(outdir + '/dot-off.png'); dot_image(True).save(outdir + '/dot-on.png')
    caption_block().save(outdir + '/caption.png', optimize=True)
    sc = open(src + '/m52xq-ubuntu-touch.script').read()
    sc = sc.replace('logo_src = Image("logo.png");', 'logo_src = Image("logo.png");\ncap_src = Image("caption.png");\n'
                    '# logo.png is wider than the original wordmark (the word "style" sticks out to the right, transparent padding on the left):\n'
                    '# the scale is taken from the width of the original wordmark so that "ubuntu touch" stays where it was\n'
                    'logo_ref_w = %d;' % ref_w, 1)
    sc = sc.replace('logo_sprite = Sprite();', 'logo_sprite = Sprite();\ncap_sprite = Sprite();', 1)
    sc = sc.replace('s = (W * 0.62) / logo_src.GetWidth();', 's = (W * 0.62) / logo_ref_w;', 1)
    sc = sc.replace('    step = W * 0.045;', '''    # white English caption above the logo: pm logo + "postmarketOS" / "Lomiri" (80 % of the width, 11 % of the height above the logo)
    cs = (W * 0.80) / cap_src.GetWidth();
    cap = cap_src.Scale(cap_src.GetWidth() * cs, cap_src.GetHeight() * cs);
    cap_sprite.SetImage(cap);
    cap_sprite.SetPosition(W / 2 - cap.GetWidth() / 2, logo_y - cap.GetHeight() - H * 0.11, 0);
    step = W * 0.045;''', 1)
    assert 'cap_sprite.SetImage' in sc and 'logo_ref_w;' in sc
    open(outdir + '/m52xq-ubuntu-touch.script', 'w').write(sc)
    pl = open(src + '/m52xq-ubuntu-touch.plymouth').read()
    open(outdir + '/m52xq-ubuntu-touch.plymouth', 'w').write(pl)
    print('тема для в5:', outdir)


if __name__ == '__main__':
    if sys.argv[1] == 'preview':
        preview(sys.argv[2])
    elif sys.argv[1] == 'stage':
        stage(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'theme':
        theme(sys.argv[2], sys.argv[3])
