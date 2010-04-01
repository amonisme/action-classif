object Actions: TActions
  Left = 370
  Top = 267
  Width = 347
  Height = 300
  Caption = 'Actions'
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
    Top = 24
    Width = 102
    Height = 16
    Caption = 'Possible actions:'
  end
  object CGauge1: TCGauge
    Left = 24
    Top = 240
    Width = 281
    Height = 9
    ShowText = False
  end
  object Button3: TButton
    Left = 232
    Top = 200
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 232
    Top = 168
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object ListBox1: TListBox
    Left = 24
    Top = 48
    Width = 193
    Height = 177
    ItemHeight = 16
    TabOrder = 2
  end
  object Button5: TButton
    Left = 232
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Add'
    TabOrder = 3
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 232
    Top = 112
    Width = 75
    Height = 25
    Caption = 'Remove'
    TabOrder = 4
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 232
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Change to'
    TabOrder = 5
    OnClick = Button7Click
  end
  object FileListBox1: TFileListBox
    Left = 152
    Top = 0
    Width = 145
    Height = 97
    ItemHeight = 16
    TabOrder = 6
    Visible = False
  end
end
