package com.smu.healyx.translation.service;

import com.smu.healyx.translation.dto.TextBlock;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

@Slf4j
@Service
public class ImageOverlayService {

    // 2x 슈퍼샘플링: 2배 해상도로 렌더링 후 다운스케일하여 소형 텍스트 선명도를 유지합니다.
    private static final int SCALE = 2;

    /**
     * 원본 이미지 위에 번역 텍스트를 오버레이하여 PNG 바이트 배열로 반환합니다.
     * PNG 무손실 압축을 사용하여 확대 시에도 텍스트 품질을 유지합니다.
     * 3x 슈퍼샘플링으로 렌더링 후 바이큐빅 다운스케일하여 소형 폰트 해상도 저하를 방지합니다.
     */
    public byte[] overlay(byte[] imageBytes, List<TextBlock> blocks) throws IOException {
        BufferedImage original = ImageIO.read(new ByteArrayInputStream(imageBytes));
        int w = original.getWidth();
        int h = original.getHeight();

        // 3x RGB 캔버스 생성
        BufferedImage hiRes = new BufferedImage(w * SCALE, h * SCALE, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = hiRes.createGraphics();

        // 흰 배경 채우기 (PNG 알파 채널 대응)
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, hiRes.getWidth(), hiRes.getHeight());

        // 원본 이미지를 3배로 확대하여 그리기
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.drawImage(original, 0, 0, w * SCALE, h * SCALE, null);

        // 텍스트 렌더링 힌트 — STROKE_PURE: 획 경계를 정수 픽셀이 아닌 정확한 좌표로 렌더링하여 선명도 향상
        // GASP: 폰트 내장 GASP 테이블 기반으로 크기별 최적 전략(힌팅/안티앨리어싱)을 자동 선택합니다.
        // LCD_HRGB는 물리 모니터 서브픽셀 배열을 전제하므로 오프스크린 렌더링 시 색깔 번짐 아티팩트가 발생합니다.
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_GASP);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setRenderingHint(RenderingHints.KEY_FRACTIONALMETRICS, RenderingHints.VALUE_FRACTIONALMETRICS_ON);
        g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);

        for (TextBlock block : blocks) {
            if (block.getTranslatedText() == null || block.getTranslatedText().isBlank()) continue;
            drawBlock(g, block, original);
        }

        g.dispose();

        // 원본 크기로 다운스케일 (바이큐빅 보간)
        BufferedImage result = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
        Graphics2D gDown = result.createGraphics();
        gDown.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        gDown.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        gDown.drawImage(hiRes, 0, 0, w, h, null);
        gDown.dispose();

        // PNG 무손실 압축으로 출력 — 확대 시 텍스트 품질 유지
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(result, "png", baos);

        return baos.toByteArray();
    }

    private void drawBlock(Graphics2D g, TextBlock block, BufferedImage original) {
        // padding을 SCALE 1px로 최소화하여 작은 바운딩박스에서 폰트 가용 높이를 최대화합니다.
        int padding = SCALE;
        int x = block.getX() * SCALE;
        int y = block.getY() * SCALE;
        int bw = block.getWidth() * SCALE;
        int bh = block.getHeight() * SCALE;
        int availableW = bw - padding * 2;
        int availableH = bh - padding * 2;

        if (availableW <= 0 || availableH <= 0) return;

        // 바운딩박스 코너 픽셀의 평균색으로 배경색을 추정하여 원본 배경을 최대한 보존합니다.
        Color bgColor = sampleBackgroundColor(original, block.getX(), block.getY(), block.getWidth(), block.getHeight());
        // 배경 밝기에 따라 텍스트 색상 결정 (밝은 배경→검정, 어두운 배경→흰색)
        Color textColor = isLight(bgColor) ? Color.BLACK : Color.WHITE;

        g.setColor(bgColor);
        g.fillRect(x, y, bw, bh);

        g.setColor(textColor);
        Font font = fitFont(g, block.getTranslatedText(), availableW, availableH);
        g.setFont(font);

        // 클리핑 영역을 바운딩박스로 제한하여 2x 폰트가 인접 블록을 침범하지 않도록 합니다.
        Shape savedClip = g.getClip();
        g.setClip(x, y, bw, bh);
        drawWrapped(g, block.getTranslatedText(), x + padding, y + padding, availableW, availableH);
        g.setClip(savedClip);
    }

    /**
     * 바운딩박스 4개 코너 픽셀의 RGB 평균으로 배경색을 추정합니다.
     * 텍스트 영역 바깥 배경을 근사하는 데 사용됩니다.
     */
    private Color sampleBackgroundColor(BufferedImage img, int bx, int by, int bw, int bh) {
        int imgW = img.getWidth();
        int imgH = img.getHeight();

        int[][] corners = {
            {bx, by},
            {bx + bw - 1, by},
            {bx, by + bh - 1},
            {bx + bw - 1, by + bh - 1}
        };

        long r = 0, g = 0, b = 0;
        int count = 0;
        for (int[] corner : corners) {
            int cx = Math.max(0, Math.min(imgW - 1, corner[0]));
            int cy = Math.max(0, Math.min(imgH - 1, corner[1]));
            // new Color(int) is 0x00RRGGBB — alpha bits are forced to 0xff internally, RGB preserved correctly
            Color c = new Color(img.getRGB(cx, cy));
            r += c.getRed();
            g += c.getGreen();
            b += c.getBlue();
            count++;
        }
        return new Color((int) (r / count), (int) (g / count), (int) (b / count));
    }

    /** 상대 휘도(luminance)로 배경 밝기를 판단합니다. */
    private boolean isLight(Color c) {
        double luminance = 0.299 * c.getRed() + 0.587 * c.getGreen() + 0.114 * c.getBlue();
        return luminance > 128;
    }

    /** 공백 없이 쓰는 언어(CJK·한글·태국어)가 포함되어 있는지 확인합니다. */
    private boolean isCJKText(String text) {
        return text.codePoints().anyMatch(cp -> {
            Character.UnicodeBlock block = Character.UnicodeBlock.of(cp);
            return block == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS
                || block == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS
                || block == Character.UnicodeBlock.HANGUL_SYLLABLES
                || block == Character.UnicodeBlock.KATAKANA
                || block == Character.UnicodeBlock.HIRAGANA
                || block == Character.UnicodeBlock.THAI;
        });
    }

    /**
     * 텍스트가 포함한 Unicode 블록에 따라 해당 문자를 렌더링할 수 있는 폰트명을 선택합니다.
     *
     * Font.canDisplayUpTo(text) == -1 이면 해당 폰트가 모든 문자를 표시할 수 있음을 의미합니다.
     * 후보 폰트를 순서대로 검사하여 처음으로 완전 표시 가능한 폰트를 반환합니다.
     *
     * 태국어: Font.SANS_SERIF(Arial 계열)는 Thai Unicode 블록을 지원하지 않아 글자가 깨짐.
     *   Windows — Tahoma, Leelawadee가 Thai를 지원
     *   Linux/Docker — TH Sarabun New, Loma (fonts-thai-tlwg 패키지)
     *   범용 fallback — Noto Sans Thai (Noto 폰트 설치 시)
     */
    private String selectFontName(String text) {
        boolean hasThai = text.codePoints().anyMatch(cp ->
                Character.UnicodeBlock.of(cp) == Character.UnicodeBlock.THAI);

        if (hasThai) {
            // Windows: Tahoma·Leelawadee  /  Linux·Docker: TH Sarabun New·Loma
            for (String name : new String[]{
                    "Tahoma", "Leelawadee", "Leelawadee UI",
                    "TH Sarabun New", "Loma", "Garuda",
                    "Noto Sans Thai", "Noto Sans"}) {
                if (new Font(name, Font.PLAIN, 12).canDisplayUpTo(text) == -1) return name;
            }
        }

        if (isCJKText(text)) {
            // Windows: Malgun Gothic(KO)·Microsoft YaHei(ZH)·MS Gothic(JA)
            // Linux·Docker: NanumGothic, Noto Sans CJK
            for (String name : new String[]{
                    "Malgun Gothic", "Microsoft YaHei", "MS Gothic",
                    "NanumGothic", "Noto Sans CJK KR", "Noto Sans CJK SC",
                    "Noto Sans CJK JP", "Noto Sans"}) {
                if (new Font(name, Font.PLAIN, 12).canDisplayUpTo(text) == -1) return name;
            }
        }

        return Font.SANS_SERIF;
    }

    /**
     * 줄바꿈을 시뮬레이션하여 텍스트가 바운딩박스에 맞는 최대 폰트 크기를 결정합니다.
     * CJK 문자(한글·중국어·일본어·태국어)는 문자 단위, 나머지는 단어 단위로 시뮬레이션합니다.
     */
    private Font fitFont(Graphics2D g, String text, int maxWidth, int maxHeight) {
        boolean cjk = isCJKText(text);
        String fontName = selectFontName(text);
        int size = Math.max(8, maxHeight);
        while (size > 8) {
            // 실제 렌더링할 1.5배 크기로 피팅 여부를 검사합니다.
            int displaySize = Math.max(16, size * 2);
            Font f = new Font(fontName, Font.PLAIN, displaySize);
            FontMetrics fm = g.getFontMetrics(f);
            boolean fits = cjk ? textFitsCJK(fm, text, maxWidth, maxHeight)
                               : textFitsByWord(fm, text, maxWidth, maxHeight);
            if (fits) break;
            size--;
        }
        return new Font(fontName, Font.PLAIN, Math.max(16, size * 2));
    }

    /** 단어 단위 줄바꿈 시뮬레이션 (영어 등 공백 구분 언어용) */
    private boolean textFitsByWord(FontMetrics fm, String text, int maxWidth, int maxHeight) {
        int lineH = fm.getHeight();
        int totalLines = 0;
        for (String paragraph : text.split("\n")) {
            int lineWidth = 0;
            int linesInParagraph = 1;
            for (String word : paragraph.split(" ")) {
                int wordW = fm.stringWidth(word);
                if (wordW > maxWidth) return false;
                int advance = lineWidth == 0 ? wordW : fm.stringWidth(" ") + wordW;
                if (lineWidth + advance > maxWidth) {
                    linesInParagraph++;
                    lineWidth = wordW;
                } else {
                    lineWidth += advance;
                }
            }
            totalLines += linesInParagraph;
        }
        return (long) totalLines * lineH <= maxHeight;
    }

    /** 문자 단위 줄바꿈 시뮬레이션 (한글·중국어·일본어 등 공백 없는 언어용) */
    private boolean textFitsCJK(FontMetrics fm, String text, int maxWidth, int maxHeight) {
        int lineH = fm.getHeight();
        int totalLines = 0;
        for (String paragraph : text.split("\n")) {
            int lineWidth = 0;
            int linesInParagraph = 1;
            for (int i = 0; i < paragraph.length(); ) {
                int cp = paragraph.codePointAt(i);
                String charStr = new String(Character.toChars(cp));
                int charW = fm.stringWidth(charStr);
                if (charW > maxWidth) return false;
                if (lineWidth + charW > maxWidth) {
                    linesInParagraph++;
                    lineWidth = charW;
                } else {
                    lineWidth += charW;
                }
                i += Character.charCount(cp);
            }
            totalLines += linesInParagraph;
        }
        return (long) totalLines * lineH <= maxHeight;
    }

    /** CJK 여부에 따라 적합한 줄바꿈 방식으로 텍스트를 렌더링합니다. */
    private void drawWrapped(Graphics2D g, String text, int x, int y, int maxWidth, int maxHeight) {
        if (isCJKText(text)) {
            drawWrappedCJK(g, text, x, y, maxWidth, maxHeight);
        } else {
            drawWrappedByWord(g, text, x, y, maxWidth, maxHeight);
        }
    }

    /** 단어 단위 줄바꿈으로 텍스트를 렌더링합니다 (공백 구분 언어용). */
    private void drawWrappedByWord(Graphics2D g, String text, int x, int y, int maxWidth, int maxHeight) {
        FontMetrics fm = g.getFontMetrics();
        int lineH = fm.getHeight();
        int curY = y + fm.getAscent();

        for (String line : text.split("\n")) {
            StringBuilder current = new StringBuilder();
            for (String word : line.split(" ")) {
                String test = current.isEmpty() ? word : current + " " + word;
                if (fm.stringWidth(test) <= maxWidth) {
                    current = new StringBuilder(test);
                } else {
                    if (curY <= y + maxHeight) g.drawString(current.toString(), x, curY);
                    curY += lineH;
                    current = new StringBuilder(word);
                }
            }
            if (!current.isEmpty() && curY <= y + maxHeight) {
                g.drawString(current.toString(), x, curY);
            }
            curY += lineH;
        }
    }

    /** 문자 단위 줄바꿈으로 텍스트를 렌더링합니다 (CJK 언어용). */
    private void drawWrappedCJK(Graphics2D g, String text, int x, int y, int maxWidth, int maxHeight) {
        FontMetrics fm = g.getFontMetrics();
        int lineH = fm.getHeight();
        int curY = y + fm.getAscent();

        for (String line : text.split("\n")) {
            StringBuilder current = new StringBuilder();
            int lineWidth = 0;
            for (int i = 0; i < line.length(); ) {
                int cp = line.codePointAt(i);
                String charStr = new String(Character.toChars(cp));
                int charW = fm.stringWidth(charStr);
                if (lineWidth + charW > maxWidth && current.length() > 0) {
                    if (curY <= y + maxHeight) g.drawString(current.toString(), x, curY);
                    curY += lineH;
                    current = new StringBuilder();
                    lineWidth = 0;
                }
                current.append(charStr);
                lineWidth += charW;
                i += Character.charCount(cp);
            }
            if (current.length() > 0 && curY <= y + maxHeight) {
                g.drawString(current.toString(), x, curY);
            }
            curY += lineH;
        }
    }
}
