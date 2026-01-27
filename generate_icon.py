#!/usr/bin/env python3
"""
LingoJourney App Icon Generator
生成 iOS App Icon（對話氣泡 + 翻譯符號設計）
"""

from PIL import Image, ImageDraw, ImageFont
import os

# 配色方案
COLORS = {
    'background_dark': '#0A1628',
    'background_light': '#0F2744',
    'primary': '#4A9EFF',
    'secondary': '#2563EB',
}

def hex_to_rgb(hex_color):
    """將 hex 色碼轉換為 RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_gradient_background(size, color1, color2):
    """創建漸變背景"""
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)

    r1, g1, b1 = hex_to_rgb(color1)
    r2, g2, b2 = hex_to_rgb(color2)

    for y in range(size):
        ratio = y / size
        r = int(r1 + (r2 - r1) * ratio)
        g = int(g1 + (g2 - g1) * ratio)
        b = int(b1 + (b2 - b1) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    return img

def draw_rounded_bubble(draw, bbox, radius, fill, outline=None, outline_width=0):
    """繪製圓角對話氣泡"""
    x1, y1, x2, y2 = bbox

    # 繪製圓角矩形
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=outline_width)

def draw_bubble_tail(draw, points, fill):
    """繪製氣泡尾巴"""
    draw.polygon(points, fill=fill)

def create_app_icon(size=1024, variant='standard'):
    """
    創建 App Icon
    variant: 'standard', 'dark', 'tinted'
    """
    # 創建漸變背景
    if variant == 'tinted':
        # 著色版使用單色背景
        img = Image.new('RGB', (size, size), hex_to_rgb(COLORS['background_dark']))
    else:
        img = create_gradient_background(size, COLORS['background_dark'], COLORS['background_light'])

    draw = ImageDraw.Draw(img)

    # 計算比例
    scale = size / 1024

    # 氣泡參數
    bubble_radius = int(60 * scale)

    # 左側氣泡（亮藍色）- 較大
    left_bubble = (
        int(180 * scale),  # x1
        int(220 * scale),  # y1
        int(580 * scale),  # x2
        int(520 * scale)   # y2
    )

    # 右側氣泡（深藍色）- 稍小，向右下偏移
    right_bubble = (
        int(440 * scale),  # x1
        int(480 * scale),  # y1
        int(840 * scale),  # x2
        int(780 * scale)   # y2
    )

    if variant == 'tinted':
        # 著色版：使用灰階
        left_color = (200, 200, 200)
        right_color = (120, 120, 120)
    else:
        left_color = hex_to_rgb(COLORS['primary'])
        right_color = hex_to_rgb(COLORS['secondary'])

    # 繪製右側氣泡（先繪製，在下層）
    draw_rounded_bubble(draw, right_bubble, bubble_radius, fill=right_color)

    # 右側氣泡尾巴（右下角）
    right_tail = [
        (int(750 * scale), int(780 * scale)),
        (int(820 * scale), int(850 * scale)),
        (int(700 * scale), int(780 * scale))
    ]
    draw_bubble_tail(draw, right_tail, right_color)

    # 繪製左側氣泡（後繪製，在上層）
    draw_rounded_bubble(draw, left_bubble, bubble_radius, fill=left_color)

    # 左側氣泡尾巴（左下角）
    left_tail = [
        (int(280 * scale), int(520 * scale)),
        (int(200 * scale), int(600 * scale)),
        (int(330 * scale), int(520 * scale))
    ]
    draw_bubble_tail(draw, left_tail, left_color)

    # 在氣泡中添加文字
    try:
        # 嘗試使用系統字體
        font_size_large = int(140 * scale)
        font_size_small = int(100 * scale)

        # macOS 系統字體路徑
        font_paths = [
            '/System/Library/Fonts/Helvetica.ttc',
            '/System/Library/Fonts/SFNSText.ttf',
            '/Library/Fonts/Arial.ttf',
            '/System/Library/Fonts/Supplemental/Arial.ttf',
        ]

        font_large = None
        font_small = None

        for font_path in font_paths:
            if os.path.exists(font_path):
                try:
                    font_large = ImageFont.truetype(font_path, font_size_large)
                    font_small = ImageFont.truetype(font_path, font_size_small)
                    break
                except:
                    continue

        if font_large is None:
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()

        # 左氣泡中的 "A"
        text_color_on_primary = hex_to_rgb(COLORS['background_dark']) if variant != 'tinted' else (50, 50, 50)

        # 計算左氣泡中心
        left_center_x = (left_bubble[0] + left_bubble[2]) // 2
        left_center_y = (left_bubble[1] + left_bubble[3]) // 2

        # 繪製 "A"
        draw.text(
            (left_center_x, left_center_y),
            "A",
            font=font_large,
            fill=text_color_on_primary,
            anchor="mm"
        )

        # 右氣泡中的 "文"
        text_color_on_secondary = (255, 255, 255) if variant != 'tinted' else (240, 240, 240)

        # 計算右氣泡中心
        right_center_x = (right_bubble[0] + right_bubble[2]) // 2
        right_center_y = (right_bubble[1] + right_bubble[3]) // 2

        # 嘗試使用支援中文的字體
        chinese_font_paths = [
            '/System/Library/Fonts/PingFang.ttc',
            '/System/Library/Fonts/STHeiti Light.ttc',
            '/System/Library/Fonts/Hiragino Sans GB.ttc',
            '/Library/Fonts/Arial Unicode.ttf',
        ]

        chinese_font = None
        for font_path in chinese_font_paths:
            if os.path.exists(font_path):
                try:
                    chinese_font = ImageFont.truetype(font_path, font_size_small)
                    break
                except:
                    continue

        if chinese_font:
            draw.text(
                (right_center_x, right_center_y),
                "文",
                font=chinese_font,
                fill=text_color_on_secondary,
                anchor="mm"
            )
        else:
            # 如果沒有中文字體，使用線條表示文字
            line_y_start = right_center_y - int(30 * scale)
            for i in range(3):
                y = line_y_start + i * int(25 * scale)
                x1 = right_center_x - int(60 * scale)
                x2 = right_center_x + int(60 * scale) - i * int(20 * scale)
                draw.line([(x1, y), (x2, y)], fill=text_color_on_secondary, width=int(8 * scale))

    except Exception as e:
        print(f"字體載入錯誤: {e}")
        # 使用簡單線條代替文字
        pass

    # 添加連接箭頭（↔）
    arrow_y = int(500 * scale)
    arrow_x = int(510 * scale)
    arrow_color = (255, 255, 255) if variant != 'tinted' else (180, 180, 180)

    # 繪製雙向箭頭
    arrow_length = int(40 * scale)
    arrow_head = int(15 * scale)
    line_width = int(6 * scale)

    # 水平線
    draw.line(
        [(arrow_x - arrow_length, arrow_y), (arrow_x + arrow_length, arrow_y)],
        fill=arrow_color,
        width=line_width
    )

    # 左箭頭
    draw.polygon([
        (arrow_x - arrow_length, arrow_y),
        (arrow_x - arrow_length + arrow_head, arrow_y - arrow_head),
        (arrow_x - arrow_length + arrow_head, arrow_y + arrow_head)
    ], fill=arrow_color)

    # 右箭頭
    draw.polygon([
        (arrow_x + arrow_length, arrow_y),
        (arrow_x + arrow_length - arrow_head, arrow_y - arrow_head),
        (arrow_x + arrow_length - arrow_head, arrow_y + arrow_head)
    ], fill=arrow_color)

    return img

def main():
    """主函數：生成所有版本的圖標"""
    output_dir = 'lingo_journey/Assets.xcassets/AppIcon.appiconset'

    # 確保輸出目錄存在
    os.makedirs(output_dir, exist_ok=True)

    # 生成三種版本
    variants = [
        ('AppIcon.png', 'standard'),
        ('AppIcon-Dark.png', 'dark'),
        ('AppIcon-Tinted.png', 'tinted')
    ]

    for filename, variant in variants:
        print(f"正在生成 {filename}...")
        icon = create_app_icon(size=1024, variant=variant)
        output_path = os.path.join(output_dir, filename)
        icon.save(output_path, 'PNG')
        print(f"已保存: {output_path}")

    # 更新 Contents.json
    contents = {
        "images": [
            {
                "filename": "AppIcon.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark"
                    }
                ],
                "filename": "AppIcon-Dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "tinted"
                    }
                ],
                "filename": "AppIcon-Tinted.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    import json
    contents_path = os.path.join(output_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"已更新: {contents_path}")

    print("\n圖標生成完成！")
    print("請在 Xcode 中打開 Assets.xcassets 確認圖標顯示正確。")

if __name__ == '__main__':
    main()
