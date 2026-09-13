object JojosViewportFrame: TJojosViewportFrame
  Left = 0
  Top = 0
  Width = 720
  Height = 460
  TabOrder = 0
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 720
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object LblStats: TLabel
      Left = 176
      Top = 8
      Width = 62
      Height = 15
      Caption = 'iniciando...'
    end
    object BtnPlay: TButton
      Left = 6
      Top = 3
      Width = 75
      Height = 24
      Caption = 'Pausar'
      TabOrder = 0
      OnClick = BtnPlayClick
    end
    object BtnReset: TButton
      Left = 87
      Top = 3
      Width = 75
      Height = 24
      Caption = 'Reiniciar'
      TabOrder = 1
      OnClick = BtnResetClick
    end
  end
  object PanelHost: TJojosViewportSurface
    Left = 0
    Top = 30
    Width = 720
    Height = 430
    Align = alClient
    OnMouseDown = PanelHostMouseDown
    OnMouseMove = PanelHostMouseMove
    OnMouseUp = PanelHostMouseUp
  end
  object Ticker: TTimer
    Interval = 16
    OnTimer = TickerTimer
    Left = 640
    Top = 40
  end
end
