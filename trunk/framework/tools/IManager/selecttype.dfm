object TypeSelect: TTypeSelect
  Left = 263
  Top = 144
  Width = 459
  Height = 132
  Caption = 'New object'
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
    Width = 183
    Height = 16
    Caption = 'Please select the object name:'
  end
  object ComboBox1: TComboBox
    Left = 24
    Top = 40
    Width = 201
    Height = 24
    Style = csDropDownList
    ItemHeight = 16
    TabOrder = 2
  end
  object Button1: TButton
    Left = 344
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 1
  end
  object Button2: TButton
    Left = 256
    Top = 40
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
  end
end
