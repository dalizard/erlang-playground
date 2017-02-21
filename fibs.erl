%%%
%%% erl -noshell -s fibs exec 40
%%%
-module(fibs).
-export([exec/1]).

exec([Arg|_]) ->
  N = list_to_integer(atom_to_list(Arg)),
  Pid = self(),
  FibFuns = [
             fun() -> {'Naive recursive', fib_naive_recursive(N)} end,
             fun() -> {'Translated array', fib_translated_array(N)} end,
             fun() -> {'Translated list', fib_translated_list(N)} end,
             fun() -> {'Reverse order list', fib_reverse_order_list(N)} end,
             fun() -> {'Minimal arithmetic', fib_minimal_arithmetic(N)} end
            ],
  lists:foreach(fun(FibFun) -> spawn(fun() ->
                                         StartTime = erlang:timestamp(),
                                         {Type, Fib} = FibFun(),
                                         EndTime = erlang:timestamp(),
                                         DeltaTime = (timer:now_diff(EndTime, StartTime) / 1000000),
                                         ListData = [Type, Fib, DeltaTime],
                                         io:format("~s: \t ~b \t ~f seconds ~n", ListData),
                                         Pid ! done
                                     end) end, FibFuns),

  wait_and_halt(length(FibFuns)).


wait_and_halt(0) -> halt();
wait_and_halt(N) ->
  receive
    done -> wait_and_halt(N - 1)
  end.

%%
%% Naive recursive
%%
fib_naive_recursive(0) -> 0;
fib_naive_recursive(1) -> 1;
fib_naive_recursive(N) -> fib_naive_recursive(N - 1) + fib_naive_recursive(N - 2).

%%
%% Naive translation of mutable array style
%%
fib_translated_array(0) -> 0;
fib_translated_array(1) -> 1;
fib_translated_array(N) ->
    Begin = 0,
    End = N + 1,
    fib_translated_array(N, End, 2, array:from_list(lists:seq(Begin, End))).

fib_translated_array(N, End, I, Fibs) when I == End -> array:get(N, Fibs);
fib_translated_array(N, End, I, Fibs) ->
    Fib = array:get(I-1, Fibs) + array:get(I-2, Fibs),
    fib_translated_array(N, End, I+1, array:set(I, Fib, Fibs)).

%%
%% Naive translation of mutable array style, but using list structure
%%
fib_translated_list(0) -> 0;
fib_translated_list(1) -> 1;
fib_translated_list(N) ->
    fib_translated_list(N + 2, 3, [0, 1]).

fib_translated_list(End, I, Fibs) when I == End -> lists:last(Fibs);
fib_translated_list(End, I, Fibs) ->
    Fib = lists:nth(I-1, Fibs) + lists:nth(I-2, Fibs),
    fib_translated_list(End, I+1, Fibs++[Fib]).


%%
%% Idiomatic use of the list (reverse order list)
%%
fib_reverse_order_list(0) -> 0;
fib_reverse_order_list(1) -> 1;
fib_reverse_order_list(N) ->
    fib_reverse_order_list(N + 1, [1,0]).

fib_reverse_order_list(End, [H|_]=L) when length(L) == End -> H;
fib_reverse_order_list(End, [A,B|_]=L) ->
    fib_reverse_order_list(End, [A+B|L]).

%%
%% Minimal arithmetic
%%
fib_minimal_arithmetic(N) when N > 0 -> fib_minimal_arithmetic(N, 0, 1).

fib_minimal_arithmetic(0, F1, _F2) -> F1;
fib_minimal_arithmetic(N, F1,  F2) -> fib_minimal_arithmetic(N - 1, F2, F1 + F2).
