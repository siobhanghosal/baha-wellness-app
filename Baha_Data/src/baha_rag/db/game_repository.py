from __future__ import annotations

import json
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class GameRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def bootstrap_player(
        self,
        *,
        player_key_hash: str,
        display_name: str,
        age_years: int,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into game_players (
                  player_key_hash,
                  display_name,
                  age_years
                )
                values (
                  :player_key_hash,
                  :display_name,
                  :age_years
                )
                on conflict (player_key_hash) do update
                set
                  display_name = excluded.display_name,
                  age_years = excluded.age_years,
                  updated_at = now()
                returning id
                """
            ),
            {
                "player_key_hash": player_key_hash,
                "display_name": display_name,
                "age_years": age_years,
            },
        )
        player_id = result.scalar_one()
        await self.session.execute(
            text(
                """
                insert into game_npc_states (
                  player_id,
                  npc_id,
                  friendship_level,
                  current_mood,
                  memories
                )
                values
                  (:player_id, 'Pip', 3, 'cheerful',
                    '["Pip knows your favourite place is the beach."]'::jsonb),
                  (:player_id, 'Maya', 2, 'hopeful',
                    '["Maya remembers that you saved her a seat at lunch."]'::jsonb),
                  (:player_id, 'Niko', 1, 'curious', '[]'::jsonb)
                on conflict (player_id, npc_id) do nothing
                """
            ),
            {"player_id": player_id},
        )
        return player_id

    async def player_id_for_key(self, player_key_hash: str) -> UUID | None:
        result = await self.session.execute(
            text(
                """
                select id
                from game_players
                where player_key_hash = :player_key_hash
                """
            ),
            {"player_key_hash": player_key_hash},
        )
        return result.scalar_one_or_none()

    async def get_state(self, player_id: UUID) -> dict[str, Any] | None:
        player_result = await self.session.execute(
            text(
                """
                select
                  id as player_id,
                  display_name,
                  age_years,
                  xp,
                  coins,
                  stars,
                  current_day,
                  pet,
                  avatar
                from game_players
                where id = :player_id
                """
            ),
            {"player_id": player_id},
        )
        player = player_result.mappings().first()
        if player is None:
            return None
        player_data = dict(player)
        if not isinstance(player_data.get("avatar"), dict):
            player_data["avatar"] = {}

        location_result = await self.session.execute(
            text(
                """
                select location_id, chapter, last_choice
                from game_location_progress
                where player_id = :player_id
                order by location_id
                """
            ),
            {"player_id": player_id},
        )
        npc_result = await self.session.execute(
            text(
                """
                select npc_id, friendship_level, current_mood, memories
                from game_npc_states
                where player_id = :player_id
                order by npc_id
                """
            ),
            {"player_id": player_id},
        )
        return {
            **player_data,
            "locations": [dict(row) for row in location_result.mappings().all()],
            "npcs": [dict(row) for row in npc_result.mappings().all()],
        }

    async def update_profile(
        self,
        *,
        player_id: UUID,
        display_name: str | None,
        pet: str | None,
        avatar: dict[str, Any] | None,
    ) -> None:
        await self.session.execute(
            text(
                """
                update game_players
                set
                  display_name = coalesce(:display_name, display_name),
                  pet = coalesce(:pet, pet),
                  avatar = coalesce(cast(:avatar as jsonb), avatar),
                  updated_at = now()
                where id = :player_id
                """
            ),
            {
                "player_id": player_id,
                "display_name": display_name,
                "pet": pet,
                "avatar": json.dumps(avatar) if avatar is not None else None,
            },
        )

    async def list_recent_story_events(
        self,
        *,
        player_id: UUID,
        location_id: str | None = None,
        limit: int = 8,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  location_id,
                  chapter,
                  choice_text,
                  coalesce(consequence ->> 'message', '') as consequence,
                  created_at
                from game_story_events
                where player_id = :player_id
                  and (:location_id is null or location_id = :location_id)
                order by created_at desc
                limit :limit
                """
            ),
            {
                "player_id": player_id,
                "location_id": location_id,
                "limit": limit,
            },
        )
        return [dict(row) for row in result.mappings().all()]

    async def record_choice(
        self,
        *,
        player_id: UUID,
        location_id: str,
        npc_id: str,
        answer: str,
        is_custom: bool,
        expected_chapter: int,
        consequence: str,
        observed_signals: list[str],
        evidence_chunk_ids: list[str],
    ) -> tuple[int, int, int, str]:
        await self.session.execute(
            text(
                """
                select id
                from game_players
                where id = :player_id
                for update
                """
            ),
            {"player_id": player_id},
        )
        progress_result = await self.session.execute(
            text(
                """
                select chapter
                from game_location_progress
                where player_id = :player_id and location_id = :location_id
                for update
                """
            ),
            {"player_id": player_id, "location_id": location_id},
        )
        current_chapter = progress_result.scalar_one_or_none() or 1
        if current_chapter != expected_chapter:
            raise ValueError(
                f"Story has already advanced to chapter {current_chapter}"
            )

        xp_earned = 45 if is_custom else 35
        coins_earned = 18 if is_custom else 12
        stars_earned = 2
        memory = f"{npc_id} remembers: you chose to {self._lower_first(answer)}."

        await self.session.execute(
            text(
                """
                update game_players
                set
                  xp = xp + :xp,
                  coins = coins + :coins,
                  stars = stars + :stars,
                  updated_at = now()
                where id = :player_id
                """
            ),
            {
                "player_id": player_id,
                "xp": xp_earned,
                "coins": coins_earned,
                "stars": stars_earned,
            },
        )
        await self.session.execute(
            text(
                """
                insert into game_location_progress (
                  player_id,
                  location_id,
                  chapter,
                  last_choice
                )
                values (
                  :player_id,
                  :location_id,
                  :next_chapter,
                  :answer
                )
                on conflict (player_id, location_id) do update
                set
                  chapter = excluded.chapter,
                  last_choice = excluded.last_choice,
                  updated_at = now()
                """
            ),
            {
                "player_id": player_id,
                "location_id": location_id,
                "next_chapter": current_chapter + 1,
                "answer": answer,
            },
        )
        await self.session.execute(
            text(
                """
                insert into game_npc_states (
                  player_id,
                  npc_id,
                  friendship_level,
                  current_mood,
                  memories
                )
                values (
                  :player_id,
                  :npc_id,
                  2,
                  'encouraged',
                  jsonb_build_array(:memory)
                )
                on conflict (player_id, npc_id) do update
                set
                  friendship_level = game_npc_states.friendship_level + 1,
                  current_mood = 'encouraged',
                  memories = game_npc_states.memories || jsonb_build_array(:memory),
                  updated_at = now()
                """
            ),
            {"player_id": player_id, "npc_id": npc_id, "memory": memory},
        )

        for signal in observed_signals:
            await self.session.execute(
                text(
                    """
                    insert into game_behaviour_profiles (
                      player_id,
                      signal_key,
                      weighted_value,
                      confidence,
                      observation_count
                    )
                    values (
                      :player_id,
                      :signal,
                      0.54,
                      0.18,
                      1
                    )
                    on conflict (player_id, signal_key) do update
                    set
                      weighted_value = least(
                        1.0,
                        game_behaviour_profiles.weighted_value * 0.88 + 0.72 * 0.12
                      ),
                      confidence = least(
                        1.0,
                        game_behaviour_profiles.confidence + 0.12
                      ),
                      observation_count =
                        game_behaviour_profiles.observation_count + 1,
                      updated_at = now()
                    """
                ),
                {"player_id": player_id, "signal": signal},
            )

        await self.session.execute(
            text(
                """
                insert into game_story_events (
                  player_id,
                  location_id,
                  chapter,
                  choice_text,
                  choice_kind,
                  consequence,
                  observed_signals,
                  evidence_chunk_ids
                )
                values (
                  :player_id,
                  :location_id,
                  :chapter,
                  :answer,
                  :choice_kind,
                  jsonb_build_object('message', :consequence),
                  cast(:signals as jsonb),
                  cast(:evidence_ids as jsonb)
                )
                """
            ),
            {
                "player_id": player_id,
                "location_id": location_id,
                "chapter": current_chapter,
                "answer": answer,
                "choice_kind": "custom" if is_custom else "guided",
                "consequence": consequence,
                "signals": json.dumps(observed_signals),
                "evidence_ids": json.dumps(evidence_chunk_ids),
            },
        )
        return xp_earned, coins_earned, stars_earned, memory

    @staticmethod
    def _lower_first(value: str) -> str:
        if not value:
            return value
        return value[:1].lower() + value[1:]
