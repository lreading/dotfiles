use crate::frame::Frame;

const GLYPH_W: usize = 3;
const GLYPH_H: usize = 5;

pub fn draw_char(frame: &mut Frame, x: usize, y: usize, ch: char, value: u8) {
    let glyph = glyph(ch);
    for (row, bits) in glyph.iter().enumerate() {
        for col in 0..GLYPH_W {
            if bits & (1 << (GLYPH_W - 1 - col)) != 0 {
                frame.set(x + col, y + row, value);
            }
        }
    }
}

#[allow(dead_code)]
pub fn draw_text(frame: &mut Frame, x: usize, y: usize, text: &str, value: u8) {
    for (idx, ch) in text.chars().enumerate() {
        draw_char(frame, x + idx * 4, y, ch, value);
    }
}

pub fn draw_tight_text(frame: &mut Frame, x: usize, y: usize, text: &str, value: u8) {
    for (idx, ch) in text.chars().take(3).enumerate() {
        draw_char(frame, x + idx * 3, y, ch, value);
    }
}

pub fn draw_vertical_text(frame: &mut Frame, x: usize, y: usize, text: &str, value: u8) {
    for (idx, ch) in text.chars().enumerate() {
        draw_char(frame, x, y + idx * GLYPH_H, ch, value);
    }
}

fn glyph(ch: char) -> [u8; GLYPH_H] {
    match ch.to_ascii_uppercase() {
        '0' => [0b111, 0b101, 0b101, 0b101, 0b111],
        '1' => [0b010, 0b110, 0b010, 0b010, 0b111],
        '2' => [0b111, 0b001, 0b111, 0b100, 0b111],
        '3' => [0b111, 0b001, 0b111, 0b001, 0b111],
        '4' => [0b101, 0b101, 0b111, 0b001, 0b001],
        '5' => [0b111, 0b100, 0b111, 0b001, 0b111],
        '6' => [0b111, 0b100, 0b111, 0b101, 0b111],
        '7' => [0b111, 0b001, 0b010, 0b010, 0b010],
        '8' => [0b111, 0b101, 0b111, 0b101, 0b111],
        '9' => [0b111, 0b101, 0b111, 0b001, 0b111],
        'A' => [0b010, 0b101, 0b111, 0b101, 0b101],
        'B' => [0b110, 0b101, 0b110, 0b101, 0b110],
        'C' => [0b111, 0b100, 0b100, 0b100, 0b111],
        'D' => [0b110, 0b101, 0b101, 0b101, 0b110],
        'E' => [0b111, 0b100, 0b110, 0b100, 0b111],
        'F' => [0b111, 0b100, 0b110, 0b100, 0b100],
        'G' => [0b111, 0b100, 0b101, 0b101, 0b111],
        'H' => [0b101, 0b101, 0b111, 0b101, 0b101],
        'I' => [0b111, 0b010, 0b010, 0b010, 0b111],
        'J' => [0b001, 0b001, 0b001, 0b101, 0b111],
        'K' => [0b101, 0b101, 0b110, 0b101, 0b101],
        'L' => [0b100, 0b100, 0b100, 0b100, 0b111],
        'M' => [0b101, 0b111, 0b111, 0b101, 0b101],
        'N' => [0b101, 0b111, 0b111, 0b111, 0b101],
        'O' => [0b111, 0b101, 0b101, 0b101, 0b111],
        'P' => [0b111, 0b101, 0b111, 0b100, 0b100],
        'Q' => [0b111, 0b101, 0b101, 0b111, 0b001],
        'R' => [0b111, 0b101, 0b111, 0b110, 0b101],
        'S' => [0b111, 0b100, 0b111, 0b001, 0b111],
        'T' => [0b111, 0b010, 0b010, 0b010, 0b010],
        'U' => [0b101, 0b101, 0b101, 0b101, 0b111],
        'V' => [0b101, 0b101, 0b101, 0b101, 0b010],
        'W' => [0b101, 0b101, 0b111, 0b111, 0b101],
        'X' => [0b101, 0b101, 0b010, 0b101, 0b101],
        'Y' => [0b101, 0b101, 0b010, 0b010, 0b010],
        'Z' => [0b111, 0b001, 0b010, 0b100, 0b111],
        '%' => [0b101, 0b001, 0b010, 0b100, 0b101],
        '-' => [0b000, 0b000, 0b111, 0b000, 0b000],
        ':' => [0b000, 0b010, 0b000, 0b010, 0b000],
        _ => [0; GLYPH_H],
    }
}
