object Main: TMain
  Left = 285
  Top = 153
  BorderStyle = bsSingle
  Caption = 'iManager'
  ClientHeight = 641
  ClientWidth = 338
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnPaint = FormPaint
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object Image1: TImage
    Left = 16
    Top = 16
    Width = 121
    Height = 89
    Stretch = True
    Visible = False
  end
  object Label17: TLabel
    Left = 40
    Top = 84
    Width = 241
    Height = 16
    Caption = 'Use File -> Open to add/modify a picture'
  end
  object Panel1: TPanel
    Left = 16
    Top = 8
    Width = 305
    Height = 617
    BevelOuter = bvNone
    TabOrder = 0
    Visible = False
    object GroupBox1: TGroupBox
      Left = 0
      Top = 0
      Width = 305
      Height = 185
      Caption = ' Image '
      TabOrder = 0
      object Label1: TLabel
        Left = 16
        Top = 24
        Width = 86
        Height = 16
        Caption = 'Original name:'
      end
      object Label2: TLabel
        Left = 16
        Top = 40
        Width = 79
        Height = 16
        Caption = 'DB file name:'
      end
      object Label3: TLabel
        Left = 16
        Top = 64
        Width = 46
        Height = 16
        Caption = 'Source:'
      end
      object Label4: TLabel
        Left = 32
        Top = 80
        Width = 63
        Height = 16
        Caption = 'Database:'
      end
      object Label5: TLabel
        Left = 32
        Top = 96
        Width = 73
        Height = 16
        Caption = 'Annotations:'
      end
      object Label6: TLabel
        Left = 32
        Top = 112
        Width = 41
        Height = 16
        Caption = 'Image:'
      end
      object Label7: TLabel
        Left = 32
        Top = 128
        Width = 55
        Height = 16
        Caption = 'FlickR id:'
      end
      object Label10: TLabel
        Left = 112
        Top = 24
        Width = 48
        Height = 16
        Caption = 'Label10'
      end
      object Label12: TLabel
        Left = 112
        Top = 40
        Width = 48
        Height = 16
        Caption = 'Label12'
      end
      object Label13: TLabel
        Left = 112
        Top = 80
        Width = 48
        Height = 16
        Caption = 'Label13'
      end
      object Label14: TLabel
        Left = 112
        Top = 96
        Width = 48
        Height = 16
        Caption = 'Label14'
      end
      object Label15: TLabel
        Left = 112
        Top = 112
        Width = 48
        Height = 16
        Caption = 'Label15'
      end
      object Label16: TLabel
        Left = 112
        Top = 128
        Width = 48
        Height = 16
        Caption = 'Label16'
      end
      object Label9: TLabel
        Left = 16
        Top = 152
        Width = 70
        Height = 16
        Caption = 'Image Size:'
      end
      object Label11: TLabel
        Left = 112
        Top = 152
        Width = 56
        Height = 16
        Caption = 'Label11'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Button1: TButton
        Left = 216
        Top = 148
        Width = 75
        Height = 25
        Caption = 'CROP'
        TabOrder = 0
        OnClick = Button1Click
      end
    end
    object GroupBox2: TGroupBox
      Left = 0
      Top = 296
      Width = 305
      Height = 113
      Caption = ' Object '
      TabOrder = 1
      object Label18: TLabel
        Left = 16
        Top = 24
        Width = 71
        Height = 16
        Caption = 'Object type:'
      end
      object Label19: TLabel
        Left = 112
        Top = 24
        Width = 48
        Height = 16
        Caption = 'Label19'
      end
      object Label8: TLabel
        Left = 176
        Top = 76
        Width = 52
        Height = 16
        Caption = 'Difficulty:'
      end
      object Label20: TLabel
        Left = 16
        Top = 76
        Width = 35
        Height = 16
        Caption = 'Pose:'
      end
      object CheckBox1: TCheckBox
        Left = 16
        Top = 48
        Width = 89
        Height = 17
        Caption = 'Truncated'
        TabOrder = 0
        OnClick = CheckBox1Click
      end
      object CheckBox2: TCheckBox
        Left = 112
        Top = 48
        Width = 81
        Height = 17
        Caption = 'Occluded'
        TabOrder = 1
        OnClick = CheckBox2Click
      end
      object Button2: TButton
        Left = 216
        Top = 24
        Width = 75
        Height = 25
        Caption = 'Remove'
        TabOrder = 2
        OnClick = Button2Click
      end
      object ComboBox1: TComboBox
        Left = 56
        Top = 72
        Width = 105
        Height = 24
        Style = csDropDownList
        ItemHeight = 16
        ItemIndex = 0
        TabOrder = 3
        Text = 'Unspecified'
        OnChange = ComboBox1Change
        Items.Strings = (
          'Unspecified'
          'Frontal'
          'Rear'
          'Left'
          'Right')
      end
      object Edit1: TEdit
        Left = 232
        Top = 72
        Width = 33
        Height = 24
        TabOrder = 4
        Text = '0'
      end
      object UpDown1: TUpDown
        Left = 265
        Top = 72
        Width = 20
        Height = 24
        Associate = Edit1
        Min = 0
        Position = 0
        TabOrder = 5
        Wrap = False
        OnChangingEx = UpDown1ChangingEx
      end
    end
    object GroupBox3: TGroupBox
      Left = 0
      Top = 424
      Width = 305
      Height = 193
      Caption = ' Action '
      TabOrder = 2
      object CheckListBox1: TCheckListBox
        Left = 16
        Top = 24
        Width = 273
        Height = 137
        OnClickCheck = CheckListBox1ClickCheck
        ItemHeight = 16
        TabOrder = 0
        OnClick = CheckListBox1Click
      end
      object CheckBox3: TCheckBox
        Left = 16
        Top = 168
        Width = 97
        Height = 17
        Caption = 'Ambiguous'
        TabOrder = 1
        OnClick = CheckBox3Click
      end
    end
    object GroupBox4: TGroupBox
      Left = 0
      Top = 192
      Width = 305
      Height = 97
      Caption = ' Object names '
      TabOrder = 3
      object Button4: TButton
        Left = 214
        Top = 56
        Width = 75
        Height = 25
        Caption = 'Delete'
        TabOrder = 0
        OnClick = Button4Click
      end
      object CheckListBox2: TCheckListBox
        Left = 16
        Top = 24
        Width = 185
        Height = 57
        OnClickCheck = CheckListBox2ClickCheck
        Columns = 2
        ItemHeight = 16
        TabOrder = 1
      end
      object Button3: TButton
        Left = 214
        Top = 24
        Width = 75
        Height = 25
        Caption = 'Add'
        TabOrder = 2
        OnClick = Button3Click
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 16
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
      OnClick = File1Click
      object Open1: TMenuItem
        Caption = 'Open...'
        ShortCut = 16463
        OnClick = Open1Click
      end
      object Close1: TMenuItem
        Caption = 'Close'
        ShortCut = 16471
        OnClick = Close1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Save2: TMenuItem
        Caption = 'Save/Add to database'
        ShortCut = 16467
        OnClick = Save2Click
      end
      object Removefromdatabase1: TMenuItem
        Caption = 'Remove from database'
        ShortCut = 16473
        OnClick = Removefromdatabase1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        ShortCut = 16453
        OnClick = Exit1Click
      end
    end
    object Parameters1: TMenuItem
      Caption = 'Parameters'
      OnClick = Parameters1Click
    end
    object Actions1: TMenuItem
      Caption = 'Actions'
      OnClick = Actions1Click
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'JPEG images|*.jpg; *.jpeg'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 48
    Top = 8
  end
end
