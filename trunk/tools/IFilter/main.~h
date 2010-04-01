//---------------------------------------------------------------------------

#ifndef mainH
#define mainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <FileCtrl.hpp>
#include <Dialogs.hpp>
#include "CGAUGES.h"
//---------------------------------------------------------------------------
class TMainform : public TForm
{
__published:	// Composants gérés par l'EDI
  TGroupBox *GroupBox1;
  TButton *Button1;
  TButton *Button2;
  TGroupBox *GroupBox2;
  TLabeledEdit *LabeledEdit3;
  TButton *Button3;
  TLabeledEdit *LabeledEdit4;
  TButton *Button4;
  TRadioGroup *RadioGroup1;
  TButton *Button5;
  TLabeledEdit *LabeledEdit5;
  TRadioGroup *RadioGroup2;
  TOpenDialog *OpenDialog1;
  TFileListBox *FileListBox1;
  TLabeledEdit *LabeledEdit2;
  TLabeledEdit *LabeledEdit1;
  TCGauge *CGauge1;
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall Button2Click(TObject *Sender);
  void __fastcall Button3Click(TObject *Sender);
  void __fastcall Button4Click(TObject *Sender);
  void __fastcall Button5Click(TObject *Sender);
private:	// Déclarations de l'utilisateur
  AnsiString get_dir(AnsiString &str);
public:		// Déclarations de l'utilisateur
  __fastcall TMainform(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainform *Mainform;
//---------------------------------------------------------------------------
#endif
