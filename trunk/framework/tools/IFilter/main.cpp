//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "main.h"
#include "../common/annotXML.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "CGAUGES"
#pragma resource "*.dfm"
TMainform *Mainform;
//---------------------------------------------------------------------------
__fastcall TMainform::TMainform(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
AnsiString TMainform::get_dir(AnsiString &str)
{
  AnsiString f = str;
  int i = 0;
  int n;
  while((n = f.Pos("\\")) != 0)
  {
    i += n;
    f = f.SubString(n+1,f.Length()-n);
  }
  return str.SubString(1,i-1);
}
//---------------------------------------------------------------------------
void __fastcall TMainform::Button1Click(TObject *Sender)
{
  AnsiString Dir = "./";
  if(SelectDirectory(Dir, TSelectDirOpts(),0))
    LabeledEdit1->Text= Dir;
}
//---------------------------------------------------------------------------
void __fastcall TMainform::Button2Click(TObject *Sender)
{
  AnsiString Dir = "./";
  if(SelectDirectory(Dir, TSelectDirOpts(),0))
    LabeledEdit2->Text= Dir;
}
//---------------------------------------------------------------------------
void __fastcall TMainform::Button3Click(TObject *Sender)
{
  AnsiString Dir = "./";
  if(SelectDirectory(Dir, TSelectDirOpts() << sdAllowCreate << sdPerformCreate << sdPrompt,0))
    LabeledEdit3->Text= Dir;
}
//---------------------------------------------------------------------------
void __fastcall TMainform::Button4Click(TObject *Sender)
{
  AnsiString Dir = "./";
  if(SelectDirectory(Dir, TSelectDirOpts() << sdAllowCreate << sdPerformCreate << sdPrompt,0))
    LabeledEdit4->Text= Dir;
}
//---------------------------------------------------------------------------
void __fastcall TMainform::Button5Click(TObject *Sender)
{
  if(LabeledEdit1->Text == "" ||
     LabeledEdit2->Text == "" ||
     LabeledEdit3->Text == "" ||
     LabeledEdit4->Text == "")
  {
    Application->MessageBox("You must specify all directories (Input et Output)", "Incorrect directory", MB_OK);
    return;
  }
  if(!DirectoryExists(LabeledEdit1->Text))
  {
    Application->MessageBox("The Input JPEG directory doesn't exist.", "Incorrect directory", MB_OK);
    return;
  }
  if(!DirectoryExists(LabeledEdit2->Text))
  {
    Application->MessageBox("The Input Annotation directory doesn't exist.", "Incorrect directory", MB_OK);
    return;
  }
  if(!DirectoryExists(LabeledEdit3->Text))
  {
    AnsiString Rest = LabeledEdit3->Text;
    AnsiString Dir = "";
    do
    {
      int i = Rest.Pos('\\');
      if(i == 0)
      {
        Dir += Rest;
        Rest = "";
      }
      else
      {
        Dir += Rest.SubString(1,i);
        Rest = Rest.SubString(i+1,Rest.Length()-i);
      }
      if(!DirectoryExists(Dir))
        MkDir(Dir);
    } while(Rest != "");
  }
  if(!DirectoryExists(LabeledEdit4->Text))
  {
    AnsiString Rest = LabeledEdit4->Text;
    AnsiString Dir = "";
    do
    {
      int i = Rest.Pos('\\');
      if(i == 0)
      {
        Dir += Rest;
        Rest = "";
      }
      else
      {
        Dir += Rest.SubString(1,i);
        Rest = Rest.SubString(i+1,Rest.Length()-i);
      }
      if(!DirectoryExists(Dir))
        MkDir(Dir);
    } while(Rest != "");
  }

  FileListBox1->ApplyFilePath(LabeledEdit1->Text);
  for(int i=0; i<FileListBox1->Items->Count; i++)
  {
    parserXML parser;

    AnsiString JPGname = FileListBox1->Items->Strings[i];
    AnsiString ANNname = JPGname.SubString(1,JPGname.Pos('.')-1);
    switch(RadioGroup1->ItemIndex)
    {
      case 0: ANNname = ANNname+".xml"; break;
    }
    AnsiString File = (LabeledEdit2->Text+"\\")+ANNname;

    document doc = parser.load_from_file(File.c_str());
    nodeIterator it = doc->get_child("annotation")->get_child("object");

    vector<TRect> motorbike;
    vector<TRect> person;
    while(!it.eol())
    {
      string name = it->get_child("name")->get_str_value();
      if(name == "motorbike" || name == "bicycle")
      {
        document bndbox = *it->get_child("bndbox");
        motorbike.push_back(TRect(bndbox->get_child("xmin")->get_int_value(),
                                  bndbox->get_child("ymin")->get_int_value(),
                                  bndbox->get_child("xmax")->get_int_value(),
                                  bndbox->get_child("ymax")->get_int_value()));
      }
      if(name == "person")
      {
        document bndbox = *it->get_child("bndbox");
        person.push_back(TRect(bndbox->get_child("xmin")->get_int_value(),
                               bndbox->get_child("ymin")->get_int_value(),
                               bndbox->get_child("xmax")->get_int_value(),
                               bndbox->get_child("ymax")->get_int_value()));
      }
      ++it;
    }
    for(unsigned int j=0;j<motorbike.size();j++)
      for(unsigned int k=0;k<person.size();k++)
      {
        int xmin = motorbike[j].left<person[k].left?person[k].left:motorbike[j].left;
        int xmax = motorbike[j].right<person[k].right?motorbike[j].right:person[k].right;
        int ymin = motorbike[j].top<person[k].top?person[k].top:motorbike[j].top;
        int ymax = motorbike[j].bottom<person[k].bottom?motorbike[j].bottom:person[k].bottom;
        if(xmin <= xmax && ymin <= ymax)
        {
          int inter = (xmax-xmin+1)*(ymax-ymin+1);
          int r1 = (motorbike[j].right-motorbike[j].left+1)*(motorbike[j].bottom-motorbike[j].top+1);
          int r2 = (person[k].right-person[k].left+1)*(person[k].bottom-person[k].top+1);
          double a = (double)inter/(sqrt(r1)*sqrt(r2));
          if(a>0.3)
          {
            AnsiString Dest = (LabeledEdit4->Text+"\\")+ANNname;
            CopyFile(File.c_str(), Dest.c_str(), false);
            File = (LabeledEdit1->Text+"\\")+JPGname;
            Dest = (LabeledEdit3->Text+"\\")+JPGname;
            CopyFile(File.c_str(), Dest.c_str(), false);
            j = motorbike.size();
            break;
          }
        }
      }

    CGauge1->Progress = (i+1)*100/FileListBox1->Items->Count;
  }
}
//---------------------------------------------------------------------------
