object Mainform: TMainform
  Left = 198
  Top = 144
  BorderStyle = bsSingle
  Caption = 'i-Filter'
  ClientHeight = 313
  ClientWidth = 697
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 120
  TextHeight = 16
  object CGauge1: TCGauge
    Left = 24
    Top = 288
    Width = 649
    Height = 8
    ShowText = False
    ForeColor = clNavy
  end
  object GroupBox1: TGroupBox
    Left = 16
    Top = 16
    Width = 321
    Height = 137
    Caption = ' Input Directories'
    TabOrder = 0
    object Button1: TButton
      Left = 224
      Top = 40
      Width = 75
      Height = 25
      Caption = 'Change'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 224
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Change'
      TabOrder = 1
      OnClick = Button2Click
    end
    object LabeledEdit2: TLabeledEdit
      Left = 16
      Top = 88
      Width = 193
      Height = 24
      EditLabel.Width = 151
      EditLabel.Height = 16
      EditLabel.Caption = 'Input Annotation Directory'
      LabelPosition = lpAbove
      LabelSpacing = 3
      TabOrder = 2
      Text = 'C:\Users\Vincent\Documents\Cours\M2\Stage\VOC2007\Annotations'
    end
    object LabeledEdit1: TLabeledEdit
      Left = 16
      Top = 40
      Width = 193
      Height = 24
      EditLabel.Width = 123
      EditLabel.Height = 16
      EditLabel.Caption = 'Input JPEG Directory'
      LabelPosition = lpAbove
      LabelSpacing = 3
      TabOrder = 3
      Text = 'C:\Users\Vincent\Documents\Cours\M2\Stage\VOC2007\JPEGImages'
    end
  end
  object GroupBox2: TGroupBox
    Left = 360
    Top = 16
    Width = 321
    Height = 137
    Caption = ' Output Directories'
    TabOrder = 1
    object LabeledEdit3: TLabeledEdit
      Left = 16
      Top = 40
      Width = 193
      Height = 24
      EditLabel.Width = 133
      EditLabel.Height = 16
      EditLabel.Caption = 'Output JPEG Directory'
      LabelPosition = lpAbove
      LabelSpacing = 3
      ReadOnly = True
      TabOrder = 0
      Text = 'C:\Users\Vincent\Documents\Cours\M2\Stage\images\motorbike'
    end
    object Button3: TButton
      Left = 224
      Top = 40
      Width = 75
      Height = 25
      Caption = 'Change'
      TabOrder = 1
      OnClick = Button3Click
    end
    object LabeledEdit4: TLabeledEdit
      Left = 16
      Top = 88
      Width = 193
      Height = 24
      EditLabel.Width = 161
      EditLabel.Height = 16
      EditLabel.Caption = 'Output Annotation Directory'
      LabelPosition = lpAbove
      LabelSpacing = 3
      ReadOnly = True
      TabOrder = 2
      Text = 'C:\Users\Vincent\Documents\Cours\M2\Stage\annotations\motorbike'
    end
    object Button4: TButton
      Left = 224
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Change'
      TabOrder = 3
      OnClick = Button4Click
    end
  end
  object RadioGroup1: TRadioGroup
    Left = 16
    Top = 168
    Width = 145
    Height = 65
    Caption = ' Input Format '
    ItemIndex = 0
    Items.Strings = (
      'XML VOC 2007')
    TabOrder = 2
  end
  object Button5: TButton
    Left = 312
    Top = 248
    Width = 75
    Height = 25
    Caption = 'Filter'
    TabOrder = 3
    OnClick = Button5Click
  end
  object LabeledEdit5: TLabeledEdit
    Left = 176
    Top = 200
    Width = 345
    Height = 24
    EditLabel.Width = 32
    EditLabel.Height = 16
    EditLabel.Caption = 'Filter:'
    LabelPosition = lpAbove
    LabelSpacing = 3
    TabOrder = 4
  end
  object RadioGroup2: TRadioGroup
    Left = 536
    Top = 168
    Width = 145
    Height = 65
    Caption = ' Output Format '
    ItemIndex = 0
    Items.Strings = (
      'XML VOC 2007')
    TabOrder = 5
  end
  object FileListBox1: TFileListBox
    Left = 280
    Top = 16
    Width = 145
    Height = 97
    ItemHeight = 16
    TabOrder = 6
    Visible = False
  end
  object OpenDialog1: TOpenDialog
    Left = 344
    Top = 8
  end
end
