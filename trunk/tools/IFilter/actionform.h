//---------------------------------------------------------------------------

#ifndef actionformH
#define actionformH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <FileCtrl.hpp>
#include "CGAUGES.h"
#include <vector>

using namespace std;
//---------------------------------------------------------------------------
class TActions : public TForm
{
__published:	// Composants gérés par l'EDI
  TLabel *Label1;
  TButton *Button3;
  TButton *Button4;
  TListBox *ListBox1;
  TButton *Button5;
  TButton *Button6;
  TButton *Button7;
  TFileListBox *FileListBox1;
  TCGauge *CGauge1;
  void __fastcall Button5Click(TObject *Sender);
  void __fastcall Button7Click(TObject *Sender);
  void __fastcall Button6Click(TObject *Sender);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall Button3Click(TObject *Sender);
private:	// Déclarations de l'utilisateur
public:		// Déclarations de l'utilisateur
  vector<bool> is_new;
  void ReplaceAction(string act, string by);
  void Save();
  __fastcall TActions(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TActions *Actions;
//---------------------------------------------------------------------------
#endif
