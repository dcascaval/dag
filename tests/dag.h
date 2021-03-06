#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

int* initRandomArrayi(int NUM_ELEMS)
{
  int* array = (int*) malloc(NUM_ELEMS * sizeof (int));
  for (int i=0; i<NUM_ELEMS; i++){
    array[i] = rand();
  }
  return array;
}

int* initRandomArrayiRange(int NUM_ELEMS,int min, int max)
{
  int* array = (int*) malloc(NUM_ELEMS * sizeof (int));
  for (int i=0; i<NUM_ELEMS; i++){
    int sample = min + (rand() % (max - min + 1));
    array[i] = sample;
  }
  return array;
}

float* initRandomArrayf(int NUM_ELEMS)
{
  float* array = (float*) malloc(NUM_ELEMS * sizeof (float));
  for (int i=0; i<NUM_ELEMS; i++){
    array[i] = (float) rand();
  }
  return array;
}

float* initRandomArrayfRange(int NUM_ELEMS,int min, int max)
{
  float* array = (float*) calloc(NUM_ELEMS,sizeof (float));
  for (int i=0; i<NUM_ELEMS; i++){
    int sample = min + (rand() % (max - min + 1));
    array[i] = (float) sample;
  }
  return array;
}

void randomizeFloatArray(float* result, int NUM_ELEMS,int min, int max)
{
  for (int i=0; i<NUM_ELEMS; i++){
    int sample = min + (rand() % (max - min + 1));
    result[i] = (float) sample;
  }
}


// Useful in a variety of testing scenarios.
void verifyArrays(const char* name, int* standard, int* test, int len){
  int passed = 0;
  for (int i = 0; i < len; i++){
      if (standard[i] != test[i]){
        printf("(%s) MISMATCH: Expected %d, Got %d\n",name,standard[i],test[i]);
        passed += 1;
      }
      if(passed >= 10){
        printf("Too many failures encountered, breaking.");
        printf("(%s) Test FAILED.\n", name);
        return;
      }
  }

  if (passed == 0){
    printf("(%s) Test Passed.\n", name);
  } else {
    printf("(%s) Test FAILED.\n", name);
  }
}

const char* getBool(bool b){
  return b ? "true" : "false";
}

void verifyBoolArrays(const char* name, bool* standard, bool* test, int len){
  int passed = 0;
  for (int i = 0; i < len; i++){
      if (standard[i] != test[i]){
        printf("(%s : %d) MISMATCH: Expected %s, Got %s\n",name, i,
                     getBool(standard[i]),getBool(test[i]));
        passed += 1;
      }
      if(passed >= 10){
        printf("Too many failures encountered, breaking.");
        printf("(%s) Test FAILED.\n", name);
        return;
      }
  }

  if (passed == 0){
    printf("(%s) Test Passed.\n", name);
  } else {
    printf("(%s) Test FAILED.\n", name);
  }
}

int almostEquals(float a, float b){
  return abs(b - a) < 1e-4;
}

void verifyFloatArrays(const char* name, float* standard, float* test, int len, int quiet){
  int passed = 0;
  for (int i = 0; i < len; i++){
      if (!almostEquals(standard[i],test[i])){
        printf("(%s) MISMATCH: Expected %f, Got %f\n",name,standard[i],test[i]);
        passed += 1;
      }
      if(passed >= 10){
        printf("Too many failures encountered, breaking.\n");
        printf("(%s) Test FAILED.\n", name);
        return;
      }
  }

  if (passed == 0 && !quiet){
    printf("(%s) Test Passed.\n", name);
  } else{
    printf("(%s) Test FAILED.\n", name);
  }
}

void verifyInt(const char* name, int a, int b){
  if (a != b){
    printf("(%s) mismatch, expected %d, got %d\n",name,a,b);
    return;
  } else{
    printf("(%s) Test Passed.\n",name);
  }
}

void verifyFloat(const char* name, float a, float b){
  if (!almostEquals(a,b)){
    printf("(%s) mismatch, expected %f, got %f\n",name,a,b);
    return;
  } else{
    printf("(%s) Test Passed.\n",name);
  }
}

static inline long minl(long a, long b){
  return a < b ? a : b;
}
