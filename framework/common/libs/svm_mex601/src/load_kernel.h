#ifndef LOAD_KERNEL_H
#define LOAD_KERNEL_H

void load_kernel_from_file(char *file);
int is_kernel_loaded();

double kernel_value(int i, int j);

void free_kernel();

#endif
