//
//  Log.h
//  SaneNetScanner
//
//  Created by Christian Speich on 05.08.12.
//  Copyright (c) 2012 Christian Speich. All rights reserved.
//

#include "LoggerClient.h"

#ifdef DEBUG

#define Log(FMT, ARGS...) LogMessageCompat(FMT, ##ARGS)

#else

#define Log(FMT, ARGS...) 

#endif
