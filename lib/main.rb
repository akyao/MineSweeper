require 'vr/vruby'
require 'vr/vrcontrol'

class ImageButton < VRButton
  include VRDrawable
  def loadFile(fname)
    @bmp=SWin::Bitmap.loadFile fname
    self.refresh
  end

  def self_paint
    drawBitmap @bmp if @bmp.is_a?(SWin::Bitmap)
  end
end

class Field < ImageButton

  IMG_DIR = "img/"
  IMG_COVERED = IMG_DIR + "covered.bmp"
  IMG_MINE = IMG_DIR + "mine.bmp"
  IMG_FLAG = IMG_DIR + "flag.bmp"
(0..8).each do |i|
  eval "IMG_OPEN#{i} = IMG_DIR + 'open#{i}.bmp'"
end

  attr_accessor :positionX, :positionY, :is_mine, :is_opened, :is_flag, :mine_count

  def init
    loadFile(IMG_COVERED)
    @is_mine = false
    @is_opend = false
    @is_flag = false
    @mine_count = 0
  end

  def clicked
    if @is_opened
    elsif parent.radio_open_on?
      open
    else
      flag
    end
    refresh
  end

  def open
    @is_opened = true
    if @is_mine
      loadFile(IMG_MINE)
      parent.left_mine_count_down
      messageBox("bomb")
    else
      loadFile(eval "IMG_OPEN#{@mine_count}")
      if @mine_count == 0
        parent.open_around_field(@positionX, @positionY)
      end
      parent.field_open_success
    end
  end

  def flag
    puts @is_flag
    if @is_flag
      @is_flag = false
      parent.left_mine_count_up
      loadFile(IMG_COVERED)
    else
      @is_flag = true
      parent.left_mine_count_down
      loadFile(IMG_FLAG)
    end
  end
  
  def put_mine
    unless(@is_mine)
      @is_mine = true
    else
      false
    end
  end

  def add_mine_count
    @mine_count += 1 unless @is_mine
  end
end

class MyForm < VRForm

  FIELDS_WIDTH = 15
  FIELDS_HEIGHT = 10
  IMAGE_WIDTH = 15
  IMAGE_HEIGHT = 15
  RADIO_WIDTH = 100
  RADIO_HEIGHT = 30
  LABEL_WIDTH = 150
  LABEL_HEIGHT = 30

  def construct
    init_fields
    init_radios
    init_labels
    @covered_field_count = FIELDS_WIDTH * FIELDS_HEIGHT - MineSweeper::MINE_COUNT
  end

  def init_fields
    (1..FIELDS_WIDTH).each do |i|
      (1..FIELDS_HEIGHT).each do |j|
        field = addControl(Field, "fieldX#{i}Y#{j}", "field", (i-1)*IMAGE_WIDTH, (j-1)*IMAGE_HEIGHT , IMAGE_WIDTH, IMAGE_HEIGHT)
        field.init
        field.positionX = i
        field.positionY = j
      end
    end
  end

  def init_radios
    addControl(VRRadiobutton,"radio_open","Open", 0, FIELDS_HEIGHT*IMAGE_HEIGHT, RADIO_WIDTH, RADIO_HEIGHT)
    addControl(VRRadiobutton,"radio_flag","Flag", 0, FIELDS_HEIGHT*IMAGE_HEIGHT + RADIO_HEIGHT, RADIO_WIDTH, RADIO_HEIGHT)
    @radio_open.check true
  end

  def init_labels
    addControl(VRStatic,"label_mine_count","", 0, FIELDS_HEIGHT*IMAGE_HEIGHT + RADIO_HEIGHT * 2, LABEL_WIDTH, LABEL_HEIGHT)
    @left_mine_count = MineSweeper::MINE_COUNT
    refresh_left_mine_count
  end

  def put_mine(i, j)
    ret = get_field(i, j).put_mine
    add_bomb_count(i, j) if ret
    return ret
  end

  def radio_open_on?
    @radio_open.checked?
  end

  def radio_flag_on?
    not radio_open_on?
  end

  def left_mine_count_up
    @left_mine_count += 1
    refresh_left_mine_count
  end

  def left_mine_count_down
    @left_mine_count -= 1
    refresh_left_mine_count
  end

  def refresh_left_mine_count
    @label_mine_count.caption = "mine count : #{@left_mine_count}"
  end

  def field_open_success
    @covered_field_count -= 1
    messageBox("clear") if @covered_field_count == 0
  end
  
  #周囲にボムの数を追加する
  def add_bomb_count(x, y)
    (x-1..x+1).each do |i|
      next if i < 1 or FIELDS_WIDTH < i
      (y-1..y+1).each do |j|
        next if j < 1 or FIELDS_HEIGHT < j
        get_field(i, j).add_mine_count
      end
    end
  end

  #周囲のフィールドを開ける
  def open_around_field(x, y)
    (x-1..x+1).each do |i|
      next if i < 1 or FIELDS_WIDTH < i
      (y-1..y+1).each do |j|
        field = get_field(i, j)
        next if j < 1 or FIELDS_HEIGHT < j
        next if field.is_opened
        field.clicked
      end
    end
  end

  def get_field(i, j)
    eval "@fieldX#{i}Y#{j}"
  end
end

class MineSweeper

  CAPTION = "Mine Sweeper"
  MINE_COUNT = 30
  MINIMUM_WIDTH = 16
  MINIMUM_HEIGHT = 37

  def init
    width = MINIMUM_WIDTH + MyForm::FIELDS_WIDTH * MyForm::IMAGE_WIDTH
    heigth = MINIMUM_HEIGHT + MyForm::FIELDS_HEIGHT * MyForm::IMAGE_HEIGHT + MyForm::RADIO_HEIGHT * 2 + MyForm::LABEL_HEIGHT
    @frm=VRLocalScreen.showForm MyForm
    @frm.move 100, 150, width, heigth
    @frm.caption = CAPTION
    set_mine
    VRLocalScreen.messageloop
  end

  def set_mine
    width = MyForm::FIELDS_WIDTH
    heigth = MyForm::FIELDS_HEIGHT
    (1..MINE_COUNT).each do
      while(!@frm.put_mine(rand(width)+1, rand(heigth)+1)) do end
    end
  end
end

game = MineSweeper.new
game.init