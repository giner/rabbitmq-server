%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Console.
%%
%%   The Initial Developers of the Original Code are Rabbit Technologies Ltd.
%%
%%   Copyright (C) 2010 Rabbit Technologies Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_mgmt_wm_permission).

-export([init/1, resource_exists/2, to_json/2,
         content_types_provided/2, content_types_accepted/2,
         is_authorized/2, allowed_methods/2, accept_content/2,
         delete_resource/2]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("rabbit_common/include/rabbit.hrl").

%%--------------------------------------------------------------------
init(_Config) -> {ok, undefined}.

content_types_provided(ReqData, Context) ->
   {[{"application/json", to_json}], ReqData, Context}.

content_types_accepted(ReqData, Context) ->
   {[{"application/json", accept_content}], ReqData, Context}.

allowed_methods(ReqData, Context) ->
    {['HEAD', 'GET', 'PUT', 'DELETE'], ReqData, Context}.

resource_exists(ReqData, Context) ->
    {case perms(ReqData) of
         none      -> false;
         not_found -> false;
         _         -> true
     end, ReqData, Context}.

to_json(ReqData, Context) ->
    {rabbit_mgmt_format:encode(
       [{permission,
         rabbit_mgmt_format:user_permissions(perms(ReqData))}]),
     ReqData, Context}.

accept_content(ReqData, Context) ->
    case perms(ReqData) of
         not_found ->
            rabbit_mgmt_util:bad_request(vhost_or_user_not_found,
                                         ReqData, Context);
         _         ->
            User = rabbit_mgmt_util:id(user, ReqData),
            VHost = rabbit_mgmt_util:id(vhost, ReqData),
            case rabbit_mgmt_util:decode(
                   ["scope", "configure", "write", "read"], ReqData) of
                [Scope, Conf, Write, Read] ->
                    try
                        rabbit_access_control:set_permissions(
                          Scope, User, VHost, Conf, Write, Read),
                        {true, ReqData, Context}
                    catch throw:{error, Error} ->
                            rabbit_mgmt_util:bad_request(
                              Error, ReqData, Context)
                    end;
                {error, Reason} ->
                    rabbit_mgmt_util:bad_request(Reason, ReqData, Context)
            end
    end.

delete_resource(ReqData, Context) ->
    User = rabbit_mgmt_util:id(user, ReqData),
    VHost = rabbit_mgmt_util:id(vhost, ReqData),
    rabbit_access_control:clear_permissions(User, VHost),
    {true, ReqData, Context}.

is_authorized(ReqData, Context) ->
    rabbit_mgmt_util:is_authorized(ReqData, Context).

%%--------------------------------------------------------------------

perms(ReqData) ->
    User = rabbit_mgmt_util:id(user, ReqData),
    case rabbit_access_control:lookup_user(User) of
        {ok, _} ->
            case rabbit_mgmt_util:vhost(ReqData) of
                not_found ->
                    not_found;
                VHost ->
                    Perms = rabbit_access_control:list_user_permissions(User),
                    Filtered = [P || {V, _, _, _, _} = P <- Perms, V == VHost],
                    case Filtered of
                        [Perm] -> Perm;
                        []     -> none
                    end
            end;
        {error, _} ->
            not_found
    end.
