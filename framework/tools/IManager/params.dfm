object Parameters: TParameters
  Left = 419
  Top = 216
  BorderIcons = [biMinimize, biMaximize]
  BorderStyle = bsSingle
  Caption = 'Parameters'
  ClientHeight = 215
  ClientWidth = 505
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 24
    Top = 132
    Width = 87
    Height = 16
    Caption = 'Next image ID:'
  end
  object LabeledEdit1: TLabeledEdit
    Left = 24
    Top = 40
    Width = 377
    Height = 24
    EditLabel.Width = 85
    EditLabel.Height = 16
    EditLabel.Caption = 'Images folder:'
    LabelPosition = lpAbove
    LabelSpacing = 3
    TabOrder = 0
    OnChange = LabeledEdit1Change
  end
  object LabeledEdit2: TLabeledEdit
    Left = 24
    Top = 96
    Width = 377
    Height = 24
    EditLabel.Width = 103
    EditLabel.Height = 16
    EditLabel.Caption = 'Annotation folder:'
    LabelPosition = lpAbove
    LabelSpacing = 3
    TabOrder = 1
    OnChange = LabeledEdit2Change
  end
  object Button1: TButton
    Left = 408
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Change'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Change'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 320
    Top = 152
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 408
    Top = 152
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
  object Edit1: TEdit
    Left = 24
    Top = 152
    Width = 121
    Height = 24
    TabOrder = 6
    Text = '0'
  end
  object UpDown1: TUpDown
    Left = 145
    Top = 152
    Width = 20
    Height = 24
    Associate = Edit1
    Min = 1
    Max = 32767
    Position = 1
    TabOrder = 7
    Wrap = False
  end
end
