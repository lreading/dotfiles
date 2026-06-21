pub const WIDTH: usize = 9;
pub const HEIGHT: usize = 34;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Frame {
    pixels: [[u8; HEIGHT]; WIDTH],
}

impl Frame {
    pub fn new() -> Self {
        Self {
            pixels: [[0; HEIGHT]; WIDTH],
        }
    }

    pub fn set(&mut self, x: usize, y: usize, value: u8) {
        if x < WIDTH && y < HEIGHT {
            self.pixels[x][y] = value;
        }
    }

    pub fn get(&self, x: usize, y: usize) -> u8 {
        self.pixels[x][y]
    }

    pub fn col(&self, x: usize) -> &[u8; HEIGHT] {
        &self.pixels[x]
    }

    pub fn fill_rect(&mut self, x: usize, y: usize, w: usize, h: usize, value: u8) {
        for px in x..x.saturating_add(w).min(WIDTH) {
            for py in y..y.saturating_add(h).min(HEIGHT) {
                self.set(px, py, value);
            }
        }
    }

    pub fn rect_outline(&mut self, x: usize, y: usize, w: usize, h: usize, value: u8) {
        if w == 0 || h == 0 {
            return;
        }
        for px in x..x.saturating_add(w).min(WIDTH) {
            self.set(px, y, value);
            self.set(px, y + h - 1, value);
        }
        for py in y..y.saturating_add(h).min(HEIGHT) {
            self.set(x, py, value);
            self.set(x + w - 1, py, value);
        }
    }

    #[allow(dead_code)]
    pub fn draw_bar_vertical(
        &mut self,
        x: usize,
        y: usize,
        w: usize,
        h: usize,
        percent: u8,
        value: u8,
    ) {
        let filled = ((h as u16 * percent.min(100) as u16) + 99) / 100;
        self.rect_outline(x, y, w, h, value.saturating_div(4).max(20));
        if filled == 0 || w <= 2 || h <= 2 {
            return;
        }
        let inner_h = h - 2;
        let fill_h = filled.min(inner_h as u16) as usize;
        let start = y + h - 1 - fill_h;
        self.fill_rect(x + 1, start, w - 2, fill_h, value);
    }

    #[allow(dead_code)]
    pub fn draw_bar_horizontal(
        &mut self,
        x: usize,
        y: usize,
        w: usize,
        h: usize,
        percent: u8,
        value: u8,
    ) {
        let filled = ((w as u16 * percent.min(100) as u16) + 99) / 100;
        self.rect_outline(x, y, w, h, value.saturating_div(4).max(20));
        if filled == 0 || w <= 2 || h <= 2 {
            return;
        }
        let inner_w = w - 2;
        let fill_w = filled.min(inner_w as u16) as usize;
        self.fill_rect(x + 1, y + 1, fill_w, h - 2, value);
    }

    #[allow(dead_code)]
    pub fn draw_spark_bars(&mut self, y: usize, bars: &[u8; WIDTH], max_h: usize, value: u8) {
        for (x, raw) in bars.iter().enumerate() {
            let h = ((*raw as usize).min(9) * max_h + 8) / 9;
            if h > 0 {
                let start = y + max_h - h;
                self.fill_rect(x, start, 1, h, value);
            }
        }
    }

    pub fn count_lit(&self) -> usize {
        let mut count = 0;
        for x in 0..WIDTH {
            for y in 0..HEIGHT {
                if self.get(x, y) > 0 {
                    count += 1;
                }
            }
        }
        count
    }
}

impl Default for Frame {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vertical_bar_fills_from_bottom() {
        let mut frame = Frame::new();
        frame.draw_bar_vertical(4, 0, 5, 8, 50, 200);
        assert_eq!(frame.get(5, 6), 200);
        assert_eq!(frame.get(5, 5), 200);
        assert_eq!(frame.get(5, 4), 200);
        assert_eq!(frame.get(5, 3), 200);
        assert_eq!(frame.get(5, 2), 0);
    }

    #[test]
    fn set_ignores_out_of_bounds() {
        let mut frame = Frame::new();
        frame.set(999, 999, 255);
        assert_eq!(frame.count_lit(), 0);
    }

    #[test]
    fn horizontal_bar_fills_from_left() {
        let mut frame = Frame::new();
        frame.draw_bar_horizontal(0, 0, 7, 5, 50, 180);
        assert_eq!(frame.get(1, 1), 180);
        assert_eq!(frame.get(2, 1), 180);
        assert_eq!(frame.get(3, 1), 180);
        assert_eq!(frame.get(5, 1), 0);
    }
}
