class_name SpriteFactory
## Asset gelene kadar kodla çizilen basit placeholder dokular (kutular ve şekiller).


static func _img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


## Ön görünüm eşek placeholder'ı (24x30). sad=true ise ağlayan versiyon.
static func donkey(sad: bool) -> Texture2D:
	var img := _img(24, 30)
	var out := Color("#2b1d14")
	var fur := Color("#8a8a96")
	var belly := Color("#c9c9d1")
	# kulaklar
	_rect(img, 4, 0, 5, 11, out); _rect(img, 5, 1, 3, 9, fur)
	_rect(img, 15, 0, 5, 11, out); _rect(img, 16, 1, 3, 9, fur)
	# kafa
	_rect(img, 3, 8, 18, 13, out); _rect(img, 4, 9, 16, 11, fur)
	_rect(img, 6, 14, 12, 6, belly)
	# gözler
	_rect(img, 7, 11, 2, 2, out); _rect(img, 15, 11, 2, 2, out)
	# burun delikleri
	_rect(img, 9, 17, 1, 1, out); _rect(img, 14, 17, 1, 1, out)
	if sad:
		_rect(img, 7, 13, 1, 3, Color("#5fc8ff")); _rect(img, 16, 13, 1, 3, Color("#5fc8ff"))
		_rect(img, 10, 19, 4, 1, out)
	else:
		_rect(img, 9, 19, 6, 1, out)
	# gövde ve bacaklar
	_rect(img, 5, 21, 14, 6, out); _rect(img, 6, 21, 12, 5, fur)
	_rect(img, 5, 26, 4, 4, out); _rect(img, 15, 26, 4, 4, out)
	return ImageTexture.create_from_image(img)


## Yuvarlak avatar placeholder'ı (16x16): sahibinin renginde gülen yüz.
static func avatar(color: Color) -> Texture2D:
	var img := _img(16, 16)
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5 - 8.0, y + 0.5 - 8.0).length()
			if d < 8.0:
				img.set_pixel(x, y, Color("#ffe0bd"))
	_rect(img, 3, 1, 10, 4, color)
	_rect(img, 5, 7, 2, 2, Color("#2b1d14")); _rect(img, 9, 7, 2, 2, Color("#2b1d14"))
	_rect(img, 5, 11, 6, 1, Color("#c0392b"))
	return ImageTexture.create_from_image(img)


## Kızgın çiftçi placeholder'ı (20x34): şapka, tulum, yaba.
static func farmer() -> Texture2D:
	var img := _img(20, 34)
	var out := Color("#2b1d14")
	_rect(img, 2, 0, 14, 3, Color("#d9a441"))      # hasır şapka
	_rect(img, 0, 3, 18, 2, Color("#b8862e"))
	_rect(img, 4, 5, 10, 8, Color("#f0b08a"))      # yüz
	_rect(img, 5, 7, 3, 1, out); _rect(img, 10, 7, 3, 1, out)   # çatık kaşlar
	_rect(img, 6, 8, 1, 1, out); _rect(img, 11, 8, 1, 1, out)
	_rect(img, 6, 11, 6, 1, Color("#8a1f1f"))
	_rect(img, 3, 13, 12, 12, Color("#c0392b"))    # gömlek
	_rect(img, 5, 15, 8, 10, Color("#2e5c9a"))     # tulum
	_rect(img, 4, 25, 4, 9, Color("#2e5c9a")); _rect(img, 10, 25, 4, 9, Color("#2e5c9a"))
	_rect(img, 18, 2, 1, 30, Color("#7a4a21"))     # yaba sapı
	_rect(img, 16, 0, 1, 4, Color("#cfcfcf")); _rect(img, 18, 0, 1, 3, Color("#cfcfcf")); _rect(img, 19, 0, 1, 4, Color("#cfcfcf"))
	_rect(img, 15, 15, 4, 2, Color("#f0b08a"))     # el
	return ImageTexture.create_from_image(img)
