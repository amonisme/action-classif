#ifndef ANNOTCONTAINERH
#define ANNOTCONTAINERH

#include <stdlib.h>
#include <vector>
#include <map>
#include <string>
#include <utility>

using namespace std;

class infoNode;

class nodeIterator
{
  private:
  string name;
  vector<infoNode*> *nodes;
  int i;

  public:
  nodeIterator(string _name, vector<infoNode*> *_n):name(_name),nodes(_n) {if(nodes) i = nodes->size()-1; else i = -1;}
  bool eol() {return i < 0;}
  void operator++ () {i--;}
  infoNode* operator ->() {if(i>=0) return (*nodes)[i]; else return NULL;}
  infoNode* operator *() {if(i>=0) return (*nodes)[i]; else return NULL;}
};

class infoNode
{
  private:
  string value;
  vector<pair<string,infoNode*> > orderedNodes;
  map<string, vector<infoNode*> > subNodes;

  public:
  infoNode() {has_value = false;};
  infoNode(const string &v) {has_value = true; value = v;};
  ~infoNode() {clear();}
  nodeIterator get_child(const string &s);
  infoNode* get_child_st(const string &s,const string &sub,const string &val);
  bool has_child(const string &s);
  infoNode* add_child(const string &s);
  infoNode* add_child(const string &s, const string &v);
  void remove_child(infoNode* child);
  
  bool has_value;
  void set_value(const string &v);
  const string& get_str_value();
  int get_int_value();
  void clear();

  friend class writerXML;
};


#endif
 