#include <dir.h>
#include <algorithm>
#include <cctype>
#include "utils.h"


//---------------------------------------------------------------------------
void MakeFullDir(const string &dir)
{
  int i = -1;
  string path;
  do
  {
    i = dir.find('\\',i+1);
    if(i != string::npos)
      path = dir.substr(0,i+1);
    else
      path = dir.substr(0,dir.length());

    mkdir(path.c_str());
  } while(i != string::npos);
}
//---------------------------------------------------------------------------
string GetDirName(const string &file)
{
  return file.substr(0,file.rfind('\\'));
}
//---------------------------------------------------------------------------
string GetFileName(const string &file)
{
  int i = file.rfind('\\')+1;
  string f = file.substr(i, file.length()-i);
  return f.substr(0,f.rfind('.'));
}
//---------------------------------------------------------------------------
string StrToLower(string &s)
{
//  std::transform(s.begin(), s.end(), s.begin(),ptr_fun(tolower));
  std::transform(s.begin(), s.end(), s.begin(),tolower);
  return s;
}
//---------------------------------------------------------------------------
