extends Node

const MAP_SIZE := 2048

func _ready():
	generate_eterna_heightmap()
	print("エターナ大陸の高さマップ生成完了")


func generate_eterna_heightmap():
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.005

	var img := Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RF)

	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var h := noise.get_noise_2d(x, y)  # -1〜1
			h = (h + 1.0) * 0.5               # 0〜1 に正規化
			img.set_pixel(x, y, Color(h, 0, 0))

	img.save_png("res://maps/eterna_height.png")
