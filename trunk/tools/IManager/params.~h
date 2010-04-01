//---------------------------------------------------------------------------

#ifndef paramsH
#define paramsH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <ComCtrls.hpp>

//---------------------------------------------------------------------------
class TParameters : public TForm
{
__published:	// Composants gérés par l'EDI
  TLabeledEdit *LabeledEdit1;
  TLabeledEdit *LabeledEdit2;
  TButton *Button1;
  TButton *Button2;
  TButton *Button3;
  TButton *Button4;
  TEdit *Edit1;
  TLabel *Label1;
  TUpDown *UpDown1;
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall Button2Click(TObject *Sender);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall ListBox1Click(TObject *Sender);
  void __fastcall LabeledEdit1Change(TObject *Sender);
  void __fastcall LabeledEdit2Change(TObject *Sender);
  void __fastcall Button3Click(TObject *Sender);
private:	// Déclarations de l'utilisateur
public:		// Déclarations de l'utilisateur
  void ShowParams();
  void VerifOK();
  __fastcall TParameters(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TParameters *Parameters;
//---------------------------------------------------------------------------
#endif
