//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "actionform.h"
#include "mainform.h"
#include "../common/annotXML.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "CGAUGES"
#pragma resource "*.dfm"
TActions *Actions;
//---------------------------------------------------------------------------
__fastcall TActions::TActions(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TActions::FormShow(TObject *Sender)
{
  ListBox1->Clear();
  is_new.resize(Main->ActionName.size());
  for(unsigned int i=0;i<Main->ActionName.size(); i++)
  {
    ListBox1->Items->Add(Main->ActionName[i].c_str());
    is_new[i] = false;
  }
  ListBox1->ItemIndex = 0;
}
//---------------------------------------------------------------------------
void __fastcall TActions::Button5Click(TObject *Sender)
{
  AnsiString Cap = "Adding an action";
  AnsiString Prompt = "Enter the new action name";
  AnsiString Value;
  if(InputQuery(Cap, Prompt, Value))
  {
    ListBox1->Items->Add(Value);
    is_new.resize(is_new.size()+1);
    is_new[is_new.size()-1] = true;
  }
}
//---------------------------------------------------------------------------
void __fastcall TActions::Button7Click(TObject *Sender)
{
  AnsiString Cap = "Changing an action";
  AnsiString Prompt = "Enter the new action name";
  AnsiString Value;
  if(InputQuery(Cap, Prompt, Value))
  {
    AnsiString Cap = "Are you sure you want to change action '";
    Cap = Cap + ListBox1->Items->Strings[ListBox1->ItemIndex];
    Cap = Cap + "' by action '" + Value + "'?";
    if(is_new[ListBox1->ItemIndex-1] || Application->MessageBox(Cap.c_str(), "Changing action", MB_YESNO|MB_ICONEXCLAMATION) == IDYES)
    {
      if(!is_new[ListBox1->ItemIndex-1])
        ReplaceAction(ListBox1->Items->Strings[ListBox1->ItemIndex].c_str(), Value.c_str());
      ListBox1->Items->Strings[ListBox1->ItemIndex] = Value;
    }
  }  
}
//---------------------------------------------------------------------------
void __fastcall TActions::Button6Click(TObject *Sender)
{
  AnsiString Cap = "Are you sure you want to delete action '";
  Cap = Cap + ListBox1->Items->Strings[ListBox1->ItemIndex];
  Cap = Cap + "'?";
  if(is_new[ListBox1->ItemIndex-1] || Application->MessageBox(Cap.c_str(), "Deleting action", MB_YESNO|MB_ICONEXCLAMATION) == IDYES)
  {
    FileListBox1->ApplyFilePath(Main->AnnotFolder.c_str());  
    if(!is_new[ListBox1->ItemIndex-1])
      ReplaceAction(ListBox1->Items->Strings[ListBox1->ItemIndex].c_str(), "");
    is_new.erase(is_new.begin()+ListBox1->ItemIndex-1);
    ListBox1->Items->Delete(ListBox1->ItemIndex);
  }
  ListBox1->ItemIndex = 0;
}
//---------------------------------------------------------------------------
void __fastcall TActions::Button3Click(TObject *Sender)
{
  Save();
}
//---------------------------------------------------------------------------
void TActions::Save()
{
  Main->ActionName.resize(ListBox1->Items->Count);
  for(int i=0;i<ListBox1->Items->Count;i++)
    Main->ActionName[i] = ListBox1->Items->Strings[i].c_str();
  Main->SaveParam();
}
//---------------------------------------------------------------------------
void TActions::ReplaceAction(string act, string by)
{
  bool deleting = (by == "");
  writerXML writer;
  parserXML parser;
  bool mod;

  for(int i=0; i<FileListBox1->Items->Count; i++)
  {
    mod = false;
    AnsiString File = Main->AnnotFolder.c_str();
    File += "\\";
    File += FileListBox1->Items->Strings[i];
    document doc = parser.load_from_file(File.c_str());

    try
    {
      nodeIterator it = doc->get_child("annotation")->get_child("object");

      while(!it.eol())
      {
        if(it->get_child("name")->get_str_value() == "person")
        {
          vector<infoNode*> toDelete;
          nodeIterator node = it->get_child("action");
          while(!node.eol())
          {
            if(node->get_child("actionname")->get_str_value() == act)
            {
              if(deleting)
                toDelete.push_back(*node);
              else
              {
                node->set_value(by);
                mod = true;
              }
            }
          }
          if(deleting)
            for(unsigned int i=0; i<toDelete.size(); i++)
              it->remove_child(toDelete[i]);
        }
        ++it;
      }
    }
    catch (char *msg)
    {
      AnsiString Txt = "In file ";
      Txt += File + ":\n";
      Txt += msg;
      Application->MessageBox(Txt.c_str(), "Error", MB_OK);
    }

    if(mod)
      writer.save_to_file(doc, File.c_str());
    
    CGauge1->Progress = (i+1)*100/FileListBox1->Items->Count;
  }

  CGauge1->Progress = 0;
  Save();  
}
//---------------------------------------------------------------------------
