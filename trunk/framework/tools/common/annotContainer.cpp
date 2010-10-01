#include "annotContainer.h"
#include "utils.h"

//------------------------------------------------------------------------------
nodeIterator infoNode::get_child(const string &s)
{
  map<string, vector<infoNode*> >::iterator it = subNodes.find(s);
  if(it == subNodes.end())
  {
    /*string msg = "Missing node '";
    msg += s+"'.";
    throw msg.c_str();*/
    return nodeIterator(s, NULL);
  }
  else
    return nodeIterator(s, &it->second);
}
//------------------------------------------------------------------------------
infoNode* infoNode::get_child_st(const string &s,const string &sub,const string &val)
{
  nodeIterator it = get_child(s);
  string low = val;
  low = StrToLower(low);
  while(!it.eol())
  {
    string s = it->get_child(sub)->get_str_value();
    s = StrToLower(s);
    if(s == low)
      return *it;
    ++it;
  }
  return NULL;
}
//------------------------------------------------------------------------------
bool infoNode::has_child(const string &s)
{
  map<string, vector<infoNode*> >::iterator it = subNodes.find(s);
  return it != subNodes.end();
}
//------------------------------------------------------------------------------
infoNode* infoNode::add_child(const string &s)
{
  infoNode* n = new infoNode;
  subNodes[s].push_back(n);
  orderedNodes.push_back(pair<string,infoNode*>(s,n));
  return n;
}
//------------------------------------------------------------------------------
infoNode* infoNode::add_child(const string &s, const string &v)
{
  infoNode* n = new infoNode(v);
  subNodes[s].push_back(n);
  orderedNodes.push_back(pair<string,infoNode*>(s,n));
  return n;
}
//------------------------------------------------------------------------------
void infoNode::remove_child(infoNode* child)
{
  for(unsigned int i=0; i<orderedNodes.size(); i++)
  {
    if(orderedNodes[i].second == child)
    {
      vector<infoNode*> &v = subNodes[orderedNodes[i].first];
      for(unsigned int j=0; j<v.size(); j++)
        if(v[j] == child)
        {
          v.erase(v.begin()+j);
          break;
        }
      if(v.size() == 0)
        subNodes.erase(orderedNodes[i].first);
      orderedNodes.erase(orderedNodes.begin()+i);        
      break;
    }
  }
  delete child;
}
//------------------------------------------------------------------------------
void infoNode::set_value(const string &v)
{
  value = v;
  has_value = true;
}
//------------------------------------------------------------------------------
const string& infoNode::get_str_value()
{
  return value;
}
//------------------------------------------------------------------------------
int infoNode::get_int_value()
{
  return atoi(value.c_str());
}
//------------------------------------------------------------------------------
void infoNode::clear()
{
  map<string, vector<infoNode*> >:: iterator it = subNodes.begin();
  while(it != subNodes.end())
  {
    vector<infoNode*> &v = it->second;
    for(unsigned int i=0; i<v.size(); i++)
      delete v[i];
    it++;
  }
}
//------------------------------------------------------------------------------

