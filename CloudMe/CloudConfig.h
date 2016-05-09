/*
 Copyright (C) 2015 Orange
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

/** set to YES if you want to have traces output with a curl syntax. Warning: can be verbose, use it only when you have issues */
#define TRACE_API_CALL NO

/** set to YES if you want bandwidth usage stats. Warning: can be verbose, use it only when you have issues */
#define TRACE_BANDWIDTH_USAGE NO

/** set to YES if you do NOT want mutiple requests simultaneously. In this case network requests are sent in sequence. If set to NO, the system will manage scheduling of multiple connections */
#define FORCE_SERIAL_REQUESTS NO
