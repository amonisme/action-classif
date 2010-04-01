//---------------------------------------------------------------------------

#ifndef MainformH
#define MainformH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Menus.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <jpeg.hpp>
#include <CheckLst.hpp>
#include <ComCtrls.hpp>
#include <vector>
#include <math.h>
#include "../common/utils.h"
#include "../common/annotXML.h"

#define MAX_SIZE  500
#define MARGIN    5
#define PENWIDTH  3
//---------------------------------------------------------------------------
class TMain : public TForm
{
__published:	// Composants gérés par l'EDI
  TMainMenu *MainMenu1;
  TMenuItem *File1;
  TMenuItem *Parameters1;
  TMenuItem *Open1;
  TMenuItem *Close1;
  TMenuItem *Removefromdatabase1;
  TMenuItem *N1;
  TMenuItem *Save2;
  TMenuItem *N2;
  TMenuItem *Exit1;
  TMenuItem *Actions1;
  TOpenDialog *OpenDialog1;
  TImage *Image1;
  TPanel *Panel1;
  TGroupBox *GroupBox1;
  TLabel *Label1;
  TLabel *Label2;
  TLabel *Label3;
  TLabel *Label4;
  TLabel *Label5;
  TLabel *Label6;
  TLabel *Label7;
  TLabel *Label10;
  TLabel *Label12;
  TLabel *Label13;
  TLabel *Label14;
  TLabel *Label15;
  TLabel *Label16;
  TLabel *Label17;
  TGroupBox *GroupBox2;
  TLabel *Label18;
  TCheckBox *CheckBox1;
  TCheckBox *CheckBox2;
  TLabel *Label9;
  TLabel *Label11;
  TGroupBox *GroupBox3;
  TCheckListBox *CheckListBox1;
  TCheckBox *CheckBox3;
  TLabel *Label19;
  TButton *Button1;
  TButton *Button2;
  TComboBox *ComboBox1;
  TEdit *Edit1;
  TUpDown *UpDown1;
  TLabel *Label8;
  TLabel *Label20;
  TGroupBox *GroupBox4;
  TButton *Button4;
  TCheckListBox *CheckListBox2;
  TButton *Button3;
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall Exit1Click(TObject *Sender);
  void __fastcall Parameters1Click(TObject *Sender);
  void __fastcall File1Click(TObject *Sender);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall Actions1Click(TObject *Sender);
  void __fastcall Open1Click(TObject *Sender);
  void __fastcall Close1Click(TObject *Sender);
  void __fastcall Save2Click(TObject *Sender);
  void __fastcall Removefromdatabase1Click(TObject *Sender);
  void __fastcall FormPaint(TObject *Sender);
  void __fastcall FormMouseMove(TObject *Sender, TShiftState Shift, int X,
          int Y);
  void __fastcall FormMouseDown(TObject *Sender, TMouseButton Button,
          TShiftState Shift, int X, int Y);
  void __fastcall CheckListBox2ClickCheck(TObject *Sender);
  void __fastcall Button3Click(TObject *Sender);
  void __fastcall Button4Click(TObject *Sender);
  void __fastcall Button2Click(TObject *Sender);
  void __fastcall CheckBox1Click(TObject *Sender);
  void __fastcall CheckBox2Click(TObject *Sender);
  void __fastcall UpDown1ChangingEx(TObject *Sender, bool &AllowChange,
          short NewValue, TUpDownDirection Direction);
  void __fastcall ComboBox1Change(TObject *Sender);
  void __fastcall CheckListBox1Click(TObject *Sender);
  void __fastcall CheckListBox1ClickCheck(TObject *Sender);
  void __fastcall CheckBox3Click(TObject *Sender);
  void __fastcall FormMouseUp(TObject *Sender, TMouseButton Button,
          TShiftState Shift, int X, int Y);
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
private:	// Déclarations de l'utilisateur
public:		// Déclarations de l'utilisateur
  int nfile;
  TColor clSelec;
  TColor clNoSelec;
  TColor clHLObj;

  document doc;
  bool FileOpen;
  bool FileOfDB;
  bool FileModified;
  bool IMGCroped;
  AnsiString DBFile;

  // Params
  int next_img;
  string ImageFolder;
  string AnnotFolder;
  vector<string> ActionName;

  Graphics::TBitmap *bmp_streched;
  Graphics::TBitmap *bmp_original;
  TJPEGImage *jpg;

  class Object
  {
    private:
    TRect box;
    int w,h,real_w,real_h;
    int offset_x, offset_y;
    TCanvas* Canvas;

    public:
    TRect coord;    
    infoNode *node;
    string type;
    bool hide;

    Object(TCanvas *_c, int ox, int oy, infoNode *_n, TRect _r, string &_t):
        Canvas(_c),
        offset_x(ox),
        offset_y(oy),
        node(_n),
        box(_r),
        type(_t)
        {hide = false;}
    void set_ratio(int _w,int _h,int rw,int rh)
    {
      w=_w;
      h=_h;
      real_w=rw;
      real_h=rh;
      if(box.left<1) box.left = 1;
      if(box.top<1) box.top = 1;
      if(box.right>w) box.right = w;
      if(box.bottom>h) box.bottom = h;
      calc_coord();
    }
    void apply_crop(int ox,int oy)
    {
      box.left = (coord.left-offset_x)*w/real_w+1;
      box.right = (coord.right-offset_x)*w/real_w+1;
      box.top = (coord.top-offset_y)*h/real_h+1;
      box.bottom = (coord.bottom-offset_y)*h/real_h+1;
      if(box.left>box.right)
      {
        int t = box.left;
        box.left = box.right;
        box.right = t;
      }
      if(box.top>box.bottom)
      {
        int t = box.top;
        box.top = box.bottom;
        box.bottom = t;
      }
      box.left-=ox;
      box.right-=ox;
      box.top-=oy;
      box.bottom-=oy;
    }
    void set_offset(int ox, int oy)
    {
      offset_x = ox;
      offset_y = oy;
    }
    void calc_coord() {
      coord.left = (box.left-1)*real_w/w + offset_x;
      coord.right = (box.right-1)*real_w/w + offset_x;
      coord.top = (box.top-1)*real_h/h + offset_y;
      coord.bottom = (box.bottom-1)*real_h/h + offset_y;
    }
    void draw(TColor c)
    {
      if(hide) return;
      Canvas->Pen->Color=c;
      Canvas->Pen->Width=PENWIDTH;
      Canvas->Brush->Style=bsClear;
      Canvas->Rectangle(TRect(coord.left-ceil((double)PENWIDTH/2.),coord.top-ceil((double)PENWIDTH/2.),
                              coord.right+ceil((double)PENWIDTH/2.)+1,coord.bottom+ceil((double)PENWIDTH/2.)+1));
    }
    double get_dist(int x, int y)
    {
      if(x<coord.left || x>coord.right) return -1.;
      if(y<coord.top || y>coord.bottom) return -1.;
      double w = (fabs(coord.right-coord.left)+1.)/2.;
      double h = (fabs(coord.bottom-coord.top)+1.)/2.;
      double dx = fabs((double)x-(double)(coord.right+coord.left)/2.);
      double dy = fabs((double)y-(double)(coord.bottom+coord.top)/2.);
      double d = sqrt(dx*dx + dy*dy);
      dx/=w;
      dy/=h;
      return d*(2.-sqrt(dx*dx + dy*dy));
    }
    void get_edge(int x, int y, bool &left, bool &right, bool &top, bool &bottom)
    {
      int cx = (coord.right+coord.left)/2;
      int cy = (coord.bottom+coord.top)/2;
      left   = abs(x-coord.left)<MARGIN && x<cx && coord.top-MARGIN<y && y<coord.bottom+MARGIN;
      right  = abs(x-coord.right)<MARGIN && x>=cx && coord.top-MARGIN<y && y<coord.bottom+MARGIN;
      top    = abs(y-coord.top)<MARGIN && y<cy && coord.left-MARGIN<x && x<coord.right+MARGIN;
      bottom = abs(y-coord.bottom)<MARGIN && y>=cy && coord.left-MARGIN<x && x<coord.right+MARGIN;
    }
    void update_rect()
    {
      box.left = (coord.left-offset_x)+1;//*w/real_w+1;
      box.right = (coord.right-offset_x)+1;//*w/real_w+1;
      box.top = (coord.top-offset_y)+1;//*h/real_h+1;
      box.bottom = (coord.bottom-offset_y)+1;//*h/real_h+1;
      if(box.left<1) box.left = 1;
      if(box.top<1) box.top = 1;
      if(box.right>w) box.right = w;
      if(box.bottom>h) box.bottom = h;      
      if(box.left>box.right)
      {
        int t = box.left;
        box.left = box.right;
        box.right = t;
      }
      if(box.top>box.bottom)
      {
        int t = box.top;
        box.top = box.bottom;
        box.bottom = t;
      }
      node->get_child("bndbox")->get_child("xmin")->set_value(IntToStr(box.left).c_str());
      node->get_child("bndbox")->get_child("ymin")->set_value(IntToStr(box.top).c_str());
      node->get_child("bndbox")->get_child("xmax")->set_value(IntToStr(box.right).c_str());
      node->get_child("bndbox")->get_child("ymax")->set_value(IntToStr(box.bottom).c_str());
    }
  };
  vector<Object> objects;
  map<string, bool> t_enabled;
  int selected;
  int highlighted;
  bool resizing;
  int resize_mode;

  int new_obj;
  int new_obj_X;
  int new_obj_Y;

  bool croping;
  bool crop_drag;
  TRect crop_rect;

  void LoadParam();
  void SaveParam();
  void LoadIMG(AnsiString FileName);
  void SaveIMG();
  void RemoveIMG();
  void CloseIMG();
  void DrawIMG();
  void ResizeAndStrech(int w, int h);
  void LoadXML(AnsiString FileName);
  void ShowInfo();
  void ShowAction();
  void ShowSize(int w, int h);

  void LoadObjects();
  void AddObject(infoNode *obj);
  void RemoveObject(int i);
  void DrawObjects();
  void HighLightObject(int i);
  void SelectObject(int i);
  void ShowObjectsInfo();
  void ShowActionInfo();

  void AddType(string type);
  void DeleteType(string type);
  void ShowHideType(string type);

  int GetResizeMode(bool left, bool right, bool top, bool bottom);
  __fastcall TMain(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMain *Main;
//---------------------------------------------------------------------------
#endif
