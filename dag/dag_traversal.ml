open Core

module Vertex = Dag.Vertex
module Vertex_view = Dag.Vertex_view

(** Topological sort of dag. *)
type traversal_tree =
  | Block of Vertex.t * traversal
  | Just of Vertex.t
  [@@deriving sexp]

and traversal = traversal_tree list [@@deriving sexp]

type poly_filterer = {
  poly_filter : 'a. 'a list -> 'a list
}

let rec traversal_to_list = List.concat_map ~f:(function
  | Just v -> [v]
  | Block (x, ys) -> x :: traversal_to_list ys)

(**
 * When reading the documentation for this context, keep in mind that
 * our algorithm for finding a traversal begins at the return
 * statement and proceeds backwards. Thus, our traversal identifies
 * things in reverse order of evaluation.
 *)
type context = {
  (* What we must have already evaluated before this point.
   * That is, a set of the vertices on which the `evaluated` set
   * depends directly.
   *)
  direct_predecessors : Vertex.Set.t;

  (* Vertices already placed into the evaluation order.
   * We add one new vertex to this each iteration of the loop.
   *)
  evaluated : Vertex.Set.t;

  curr_bound_parallel_vertex : Vertex.t option;
} [@@deriving sexp]

let transitive_predecessor_closure (dag : Dag.dag) : Vertex.Set.t Vertex.Map.t =
  let init = Vertex.Map.of_alist_exn
    (Dag.vertices dag |> Set.to_list |> List.map ~f:(fun vtx ->
      (vtx, Vertex.Set.of_list (Dag.predecessors dag vtx))))
  in
  let rec loop m =
    let any_changed = ref false in
    let m' = Map.mapi m ~f:(fun ~key ~data:x ->
      let x = Set.fold x ~init:x ~f:(fun acc elt ->
        let acc' = List.fold_left (Dag.predecessors dag elt) ~init:acc ~f:Set.add in
        if Set.length acc <> Set.length acc' then any_changed := true;
        acc')
      in
      (* Roughly: we wish to add as (transitively closed) predecessors to a parallel block
       * all predecessors of members of the block that are not themselves in the block.
       *)
      let vs = Dag.vertices_in_block dag ~parallel_block_vertex:key in
      Set.fold vs ~init:x ~f:(fun acc v ->
        Set.union acc (Set.filter ~f:(Fn.non (Set.mem vs)) (Map.find m v |> Option.value ~default:Vertex.Set.empty)))
    )
    in
    if !any_changed then loop m' else m
  in loop init

let traversals_with_filter (dag : Dag.dag) ~seed : traversal =

  Random.init seed;

  let predecessors = transitive_predecessor_closure dag in

  let isn't_value (v : Vertex.t) : bool = match Dag.view dag v with
    | Vertex_view.Input _ -> false
    | Vertex_view.Literal _ -> false
    | _ -> true
  in

  (* How do I evaluate a vertex? *)
  let rec loop_of_vertex ?(curr=None) (vertex : Vertex.t) : (traversal * Vertex.Set.t) =
    loop ~acc:[] {
      curr_bound_parallel_vertex = curr;
      direct_predecessors = Vertex.Set.singleton vertex;
      evaluated = Vertex.Set.empty;
    }

  (* Arbitrarily find a way to evaluate starting from a context. *)
  and loop ~(acc : traversal) (ctx : context) : (traversal * Vertex.Set.t) =
    let candidates = Set.filter ctx.direct_predecessors ~f:(fun v ->
      isn't_value v
        && Set.is_subset (Dag.successors dag v) ~of_:ctx.evaluated
        && not (Set.mem ctx.evaluated v)
    ) in
    let loop_with (vertex : Vertex.t) (subtraversal, remaining : traversal * Vertex.Set.t)
    : (traversal * Vertex.Set.t) =
      let predecessors_minus_vertex = Set.remove ctx.direct_predecessors vertex in
      let direct_predecessors =
        Vertex.Set.of_list (Dag.predecessors dag vertex)
          |> Set.union predecessors_minus_vertex
      in
      let ctx' = {
        curr_bound_parallel_vertex = ctx.curr_bound_parallel_vertex;
        direct_predecessors = Set.union direct_predecessors remaining;
        evaluated =
          Set.union
            ctx.evaluated
            (Vertex.Set.of_list (vertex :: traversal_to_list subtraversal));
      } in
      loop ctx' ~acc:(
        let elem = match Dag.view dag vertex with
          | Vertex_view.Parallel_block _ -> Block (vertex, subtraversal)
          | _ -> Just vertex
        in elem :: acc)
    in
    begin
      match Set.to_list candidates |> List.random_element with
      | None -> (acc, Vertex.Set.empty)
      | Some vertex ->
          let subtraversals =
            Option.value_map (Dag.unroll dag vertex) ~default:([], Vertex.Set.empty)
              ~f:(loop_of_vertex ~curr:(
                begin
                  match Dag.view dag vertex with
                  | Vertex_view.Parallel_block (bd_vtx, _) -> Some bd_vtx
                  | _ -> None
                end))
          in
          let result = loop_with vertex subtraversals in
          result
          (*begin
            match ctx.curr_bound_parallel_vertex with
            | Some pvtx when not (Set.mem (Map.find_exn predecessors vertex) pvtx) ->
                let results2 = loop ~acc { ctx with direct_predecessors = Set.remove ctx.direct_predecessors vertex } in
                List.random_element_exn [ result; Tuple2.map_snd results2 ~f:(Fn.flip Vertex.Set.add vertex); ]
            | _ -> result
          end*)
    end
  in
  fst (loop_of_vertex (Dag.return_vertex dag))

let any_traversal (dag : Dag.dag) ~seed : traversal =
  traversals_with_filter dag ~seed

(*let all_traversals ?(n=`Take_all_of_'em) =
  traversals_with_filter ~n:(match n with
    | `Take_all_of_'em -> None
    | `Actually_I_don't_want_all_of_them
        (`Please_stop_at n) -> Some n)*)
