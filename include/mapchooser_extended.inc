/**
 * vim: set ts=4 :
 * =============================================================================
 * MapChooser Extended
 * Creates a map vote at appropriate times, setting sm_nextmap to the winning
 * vote
 *
 * MapChooser Extended (C)2011-2013 Powerlord (Ross Bemrose)
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#if defined _mapchooser_extended_included_
  #endinput
#endif
#define _mapchooser_extended_included_
#include <mapchooser>

// MCE 1.9 series

enum CanNominateResult
{
	CanNominate_No_VoteFull,		/** No, nominations list is full */
	CanNominate_No_VoteInProgress,	/** No, map vote is in progress */
	CanNominate_No_VoteComplete,	/** No, map vote is completed */
	CanNominate_Yes,				/** Yes, you can nominate */
};


/**
 * Called whenever warning timer starts
 * 
 */
forward OnMapVoteWarningStart();

/**
 * Called whenever runoff warning timer starts
 */
forward OnMapVoteRunnoffWarningStart();

/**
 * Called whenever the timer ticks
 */
forward OnMapVoteWarningTick(time);

/**
 * Called whenever vote starts
 * 
 * @deprecated Will be removed in MapChooser 1.8.  Use OnMapVoteStarted instead.
 */
forward OnMapVoteStart();

/**
 * Called whenever vote ends
 */
forward OnMapVoteEnd(const String:map[]);

/**
 * Is a map on the current game's official list?
 * This should be treated as informative only.
 * 
 * @param map 	Name of map to check
 * @return 		true if it's on the list of official maps for this game
 */
native bool:IsMapOfficial(const String:map[]);

/**
 * Is nominate allowed?
 * 
 * @return		A CanNominateResult corresponding to whether a vote is allowed or not
 */
native CanNominateResult:CanNominate();

public SharedPlugin:__pl_mapchooser_extended = 
{
	name = "mapchooser",
	file = "mapchooser_extended.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

stock bool IsNiceMap(const char[] map)
{
	if (
			StrEqual(map, "ze_DOOM_wad_BV4_4", false) ||
			StrEqual(map, "ze_fapescape_p5", false) ||
			StrEqual(map, "ze_fapescape_rote_v1_1", false) ||
			StrEqual(map, "ze_ffvii_mako_reactor_p8", false) ||
			StrEqual(map, "ze_FFVII_Mako_Reactor_v5_3_v5", false) ||
			StrEqual(map, "ze_ffxii_feywood_b3_1_e2", false) ||
			StrEqual(map, "ze_ffxii_paramina_rift_v1_3_ps1_2", false) ||
			StrEqual(map, "ze_ffxii_westersand_v7_2_e6", false) ||
			StrEqual(map, "ze_ffxiv_wanderers_palace_v2_2", false) ||
			StrEqual(map, "ze_frostdrake_tower_v1", false) ||
			StrEqual(map, "ze_lila_panic_escape_v1_1", false) ||
			StrEqual(map, "ze_minecraft_adventure_v1_3d", false) ||
			StrEqual(map, "ze_paper_escaper_v6_6c2", false) ||
			StrEqual(map, "ze_Pirates_Port_Royal_v4_2", false) ||
			StrEqual(map, "ze_Portal_Story_v3_2fix", false) ||
			StrEqual(map, "ze_predator_ultimate_p7", false) ||
			StrEqual(map, "ze_reloaded_v1_e10", false) ||
			StrEqual(map, "ze_sandstorm_v7_1_e4", false) ||
			StrEqual(map, "ze_santassination_v2", false) ||
			StrEqual(map, "ze_shroomforest2_b4_e7", false) ||
			StrEqual(map, "ze_shroomforest_v4_4fix_e6", false) ||
			StrEqual(map, "ze_sunlight_v2_0_p8", false) ||
			StrEqual(map, "ze_tesv_skyrim_v5_6", false) ||
			StrEqual(map, "ze_tilex_possession_v2_3", false) ||
			StrEqual(map, "ze_UT2004_Convoy_p2", false) || 
			StrEqual(map, "ze_surf_sahok_v1", false) ||
			StrEqual(map, "ze_christmas_infection_v2_7_air", false) ||
			StrEqual(map, "ze_toaster_p3", false) ||
			StrEqual(map, "ze_Sit_Caelum_Paradisus_b6_2", false)
		)
		return true;

	return false;
}

stock bool GetMapTrans(const char[] map, char[] szTrans)
{
	if(StrEqual(map, "ze_ffvii_mako_reactor_p8", false))
	{
		Format(szTrans, 256, "%s\n[最终幻想-魔光炉: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_FFVII_Mako_Reactor_v5_3_v5", false))
	{
		Format(szTrans, 256, "%s\n[最终幻想-魔光炉: 4+1关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_fapescape_p5", false))
	{
		Format(szTrans, 256, "%s\n[乐高方块剧场: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_10th_Station_vFaT10", false))
	{
		Format(szTrans, 256, "%s\n[第十地铁站: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_13_v2", false))
	{
		Format(szTrans, 256, "%s\n[十三: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ALIEN_mountain_escape_p3", false))
	{
		Format(szTrans, 256, "%s\n[高山逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ALIEN_mountain_escape_p3", false))
	{
		Format(szTrans, 256, "%s\n[高山逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ApertureScience_p2", false))
	{
		Format(szTrans, 256, "%s\n[光圈科技-传送门: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_DOOM_wad_BV4_4", false))
	{
		Format(szTrans, 256, "%s\n[毁灭战士: 3关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_farmhouse_v9", false))
	{
		Format(szTrans, 256, "%s\n[农场: 4关|神器|BOSS|高奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_aztecnoob_p2", false))
	{
		Format(szTrans, 256, "%s\n[阿兹特克人: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_aztec_temple_go_v2", false))
	{
		Format(szTrans, 256, "%s\n[阿兹特克神殿: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_bastion_nav72", false))
	{
		Format(szTrans, 256, "%s\n[堡垒: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_bathroom_v2_3", false))
	{
		Format(szTrans, 256, "%s\n[浴室逃脱: 2关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_biohazard2_rpd_004_p3", false))
	{
		Format(szTrans, 256, "%s\n[生化危机-警察局: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_biohazard2_sewer_004_p8", false))
	{
		Format(szTrans, 256, "%s\n[生化危机-下水道: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_boacceho_p3", false))
	{
		Format(szTrans, 256, "%s\n[地抛球: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_bp-infested-prison_p2", false))
	{
		Format(szTrans, 256, "%s\n[监狱: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_bunker_escape_v1_2", false))
	{
		Format(szTrans, 256, "%s\n[地垒逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Breakable_p3", false))
	{
		Format(szTrans, 256, "%s\n[破碎的墙: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_cathedral_b1_1", false))
	{
		Format(szTrans, 256, "%s\n[大教堂: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_cheezylab_beta7", false))
	{
		Format(szTrans, 256, "%s\n[秘密基地: 1关|BOSS|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_colorlicouspilar_p4", false))
	{
		Format(szTrans, 256, "%s\n[多彩戏剧: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_csgo_grey2", false))
	{
		Format(szTrans, 256, "%s\n[灰白世界: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_cyberderp_p3", false))
	{
		Format(szTrans, 256, "%s\n[网格世界: 1关|神器|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_dangerous_waters_v1h_03_b", false))
	{
		Format(szTrans, 256, "%s\n[危险的水: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_deepice_p3", false))
	{
		Format(szTrans, 256, "%s\n[深冰: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_dingo_land_v1", false))
	{
		Format(szTrans, 256, "%s\n[消失的土地: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_escape_the_eye_p2", false))
	{
		Format(szTrans, 256, "%s\n[逃亡之眼: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_evil_mansion_v1_final", false))
	{
		Format(szTrans, 256, "%s\n[邪恶大夏: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_FFXII_Westersand_v7_2_e6", false))
	{
		Format(szTrans, 256, "%s\n[最终幻想-西沙: 5+1关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_firewall_laboratory_part2_p2", false))
	{
		Format(szTrans, 256, "%s\n[防火墙实验室: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Flying_World_p", false))
	{
		Format(szTrans, 256, "%s\n[飞行世界: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_forgotten_facility_p2", false))
	{
		Format(szTrans, 256, "%s\n[被遗忘的工厂: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_frostdrake_tower_v1", false))
	{
		Format(szTrans, 256, "%s\n[寒霜之塔: 1关|BOSS|解谜|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_games_v2_1", false))
	{
		Format(szTrans, 256, "%s\n[小游戏: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_great_crate_escape_v5", false))
	{
		Format(szTrans, 256, "%s\n[大箱子逃亡: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Halloween_House_b3", false))
	{
		Format(szTrans, 256, "%s\n[万圣节之家: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_halo_poa_p4", false))
	{
		Format(szTrans, 256, "%s\n[光晕: 1关|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_haunted_lab_escape_v2c_e3", false))
	{
		Format(szTrans, 256, "%s\n[闹鬼的试验室: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_hold_em_v8", false))
	{
		Format(szTrans, 256, "%s\n[鬼脸长廊: 1关|BOSS|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_hypernova_v2fix2", false))
	{
		Format(szTrans, 256, "%s\n[超新星: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_icecap_escape_v5_p", false))
	{
		Format(szTrans, 256, "%s\n[西瓜橘子: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_inboxed_final", false))
	{
		Format(szTrans, 256, "%s\n[天空盒: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_insanitycity_final", false))
	{
		Format(szTrans, 256, "%s\n[错乱的都市: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_interception_p2", false))
	{
		Format(szTrans, 256, "%s\n[拦截: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Island_Escape_p3", false))
	{
		Format(szTrans, 256, "%s\n[荒岛逃生: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_jurassicpark_csgo", false))
	{
		Format(szTrans, 256, "%s\n[侏罗纪公园: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_k19_escape_v5", false))
	{
		Format(szTrans, 256, "%s\n[逃出地下基地: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_kaffe_escape_v2", false))
	{
		Format(szTrans, 256, "%s\n[咖啡仓库大逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_lab_v5", false))
	{
		Format(szTrans, 256, "%s\n[实验室: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_lotr_helms_deep_v5_p6", false))
	{
		Format(szTrans, 256, "%s\n[魔戒-圣盔谷: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_LOTR_Mines_of_Moria_p2", false))
	{
		Format(szTrans, 256, "%s\n[魔戒-矿坑: 1关|神器|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_magic_ship_fix", false))
	{
		Format(szTrans, 256, "%s\n[魔法船: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_mario_tower_v4_p2", false))
	{
		Format(szTrans, 256, "%s\n[马里奥之塔: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_minecraft_v1_1_p3", false))
	{
		Format(szTrans, 256, "%s\n[我的世界: 1关|神器|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_mirrors_edge_reborn_v2", false))
	{
		Format(szTrans, 256, "%s\n[镜之边缘: 4关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_modafuka_v1-2", false))
	{
		Format(szTrans, 256, "%s\n[逃出树脂工厂: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_motanuminc_p2", false))
	{
		Format(szTrans, 256, "%s\n[光圈科技大逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_mountainpass_b5", false))
	{
		Format(szTrans, 256, "%s\n[山口基地: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_nostromo_v1_0b", false))
	{
		Format(szTrans, 256, "%s\n[诺斯托罗莫: 1关|低奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_nuke_v2", false))
	{
		Format(szTrans, 256, "%s\n[导弹基地: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_NY_marathon_p2", false))
	{
		Format(szTrans, 256, "%s\n[马拉松竞赛: 1关|神器|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ocean_base_escape_v4", false))
	{
		Format(szTrans, 256, "%s\n[海洋基地大逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_paper_escaper_v6_6c2", false))
	{
		Format(szTrans, 256, "%s\n[纸质大逃亡: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_paradise_v2_csgo", false))
	{
		Format(szTrans, 256, "%s\n[火山基地: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_parkour_fix", false))
	{
		Format(szTrans, 256, "%s\n[跑酷: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_pipescape_v1", false))
	{
		Format(szTrans, 256, "%s\n[管垢: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Pirates_Port_Royal_v4_2", false))
	{
		Format(szTrans, 256, "%s\n[加勒比-罗亚港: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_pitchblack_p2", false))
	{
		Format(szTrans, 256, "%s\n[星际传奇: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Portal_Story_v3_2fix", false))
	{
		Format(szTrans, 256, "%s\n[传送门的故事: 3关|BOSS|神器|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_PoR_island_p3", false))
	{
		Format(szTrans, 256, "%s\n[波尔河岛: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_POTC_IV_v6_1fix", false))
	{
		Format(szTrans, 256, "%s\n[加勒比海盗-不老泉: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_potc_p3", false))
	{
		Format(szTrans, 256, "%s\n[加勒比海盗: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_predator_ultimate_p7", false))
	{
		Format(szTrans, 256, "%s\n[铁血战士: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_prototype_v3_2", false))
	{
		Format(szTrans, 256, "%s\n[原型: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Random_p2", false))
	{
		Format(szTrans, 256, "%s\n[随机大爆炸: 1关|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_reconnoiter_b4", false))
	{
		Format(szTrans, 256, "%s\n[勘察: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_revolution_part1", false))
	{
		Format(szTrans, 256, "%s\n[革命: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_rising_waters_beta", false))
	{
		Format(szTrans, 256, "%s\n[上升的水: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_rockescape_2013_v1_3_3", false))
	{
		Format(szTrans, 256, "%s\n[岩石山: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Rooftop_Runaway1_p", false))
	{
		Format(szTrans, 256, "%s\n[屋顶逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sandstorm_v7_1_e4", false))
	{
		Format(szTrans, 256, "%s\n[沙尘暴: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_santassination_v2", false))
	{
		Format(szTrans, 256, "%s\n[狮子王: 8+2关|神器|BOSS|解谜|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_saw_p3", false))
	{
		Format(szTrans, 256, "%s\n[电锯惊魂: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sewage_processing_b7", false))
	{
		Format(szTrans, 256, "%s\n[污水处理厂: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_shroomforest2_b4_e7", false))
	{
		Format(szTrans, 256, "%s\n[新·蘑菇世界2: 7+1关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_shroomforest2_p4", false))
	{
		Format(szTrans, 256, "%s\n[蘑菇世界2: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_shroomforest_v3_p3", false))
	{
		Format(szTrans, 256, "%s\n[蘑菇世界: 6关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_skyscraper_city_csgo1", false))
	{
		Format(szTrans, 256, "%s\n[摩天楼: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sorrento_escape_0_9", false))
	{
		Format(szTrans, 256, "%s\n[索伦托逃生: 5关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_spacestation_og_final", false))
	{
		Format(szTrans, 256, "%s\n[空间站: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sst2_p", false))
	{
		Format(szTrans, 256, "%s\n[星河舰队: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_super_metroid", false))
	{
		Format(szTrans, 256, "%s\n[超级银河战士: 1关|BOSS|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_surf_danger_p2", false))
	{
		Format(szTrans, 256, "%s\n[滑翔逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_surf_facility_p4", false))
	{
		Format(szTrans, 256, "%s\n[金字塔滑翔: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_test", false))
	{
		Format(szTrans, 256, "%s\n[考验: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_tesv_skyrim_v5_6", false))
	{
		Format(szTrans, 256, "%s\n[上古卷轴-天际: 5关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_texturescape_p2", false))
	{
		Format(szTrans, 256, "%s\n[乐高陷阱: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_thelostworld_v2_csgo", false))
	{
		Format(szTrans, 256, "%s\n[失落的世界: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_tilex_escape_e3", false))
	{
		Format(szTrans, 256, "%s\n[地站逃亡: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_thousand_steps_b7", false))
	{
		Format(szTrans, 256, "%s\n[千步工厂逃亡: 1关|低奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_titanic_escape_v2", false))
	{
		Format(szTrans, 256, "%s\n[泰坦尼克号: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_tkara_v3", false))
	{
		Format(szTrans, 256, "%s\n[塔卡拉地下基地: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_townscape_vfinallqfix2", false))
	{
		Format(szTrans, 256, "%s\n[城市面容: 3关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_trainescape_final_p2", false))
	{
		Format(szTrans, 256, "%s\n[火车逃亡记: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_underground_escape_final_e2", false))
	{
		Format(szTrans, 256, "%s\n[地下逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_unknow_escape_v4", false))
	{
		Format(szTrans, 256, "%s\n[未知的逃亡: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_urban_laby_of_death_p2", false))
	{
		Format(szTrans, 256, "%s\n[迷宫: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_UT2004_Convoy_p2", false))
	{
		Format(szTrans, 256, "%s\n[虚幻竞技场: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_volcano_escape_v4fix", false))
	{
		Format(szTrans, 256, "%s\n[火山逃亡: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_winter_p3", false))
	{
		Format(szTrans, 256, "%s\n[冬天城市: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_zk_fapescape_p3", false))
	{
		Format(szTrans, 256, "%s\n[伪乐高剧场: 1关|BOSS|神器|低奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_zombiemod_corporation_p2", false))
	{
		Format(szTrans, 256, "%s\n[僵尸公司: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_zombierig_v4_3_pm1", false))
	{
		Format(szTrans, 256, "%s\n[僵尸回想: 2关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_lila_panic_escape_v1_1", false))
	{
		Format(szTrans, 256, "%s\n[里拉大逃亡: 9关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_reloaded_v1_e10", false))
	{
		Format(szTrans, 256, "%s\n[合金装备: 3关|BOSS|神器|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_minecraft_adventure_v1_3d", false))
	{
		Format(szTrans, 256, "%s\n[我的世界大冒险: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_platformer_b2", false))
	{
		Format(szTrans, 256, "%s\n[捡金币: 1关|娱乐|神器|低奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sunlight_v2_0_p8", false))
	{
		Format(szTrans, 256, "%s\n[日光: 4+1关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_destruction_of_exorath_v3_1", false))
	{
		Format(szTrans, 256, "%s\n[摧毁早熟的exo: 5关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_timesplitters_p", false))
	{
		Format(szTrans, 256, "%s\n[时空分裂者: 1关|BOSS|神器|中奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_tilex_possession_v2_7", false))
	{
		Format(szTrans, 256, "%s\n[跳刀竞赛: 5+1关|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Parking_p4", false))
	{
		Format(szTrans, 256, "%s\n[地停车场大楼: 4关|神器|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_naruto_v1_1", false))
	{
		Format(szTrans, 256, "%s\n[火影忍者: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_sky_athletic_v7_3", false))
	{
		Format(szTrans, 256, "%s\n[天空体育: 4关|神器|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_colors_p3", false))
	{
		Format(szTrans, 256, "%s\n[乐高逃亡: 1关|神器|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_surf_sahok_v1", false))
	{
		Format(szTrans, 256, "%s\n[萨霍宫滑翔: 1关|BOSS|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_gris_a4_9_9", false))
	{
		Format(szTrans, 256, "%s\n[格里斯: 3关|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ffxii_feywood_b3_1_e2", false))
	{
		Format(szTrans, 256, "%s\n[FF12-幻妖之森: 5+1关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ffxii_paramina_rift_v1_3_ps1_2", false))
	{
		Format(szTrans, 256, "%s\n[FF12-帕拉米娅: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_shroomforest_v4_4fix_e6", false))
	{
		Format(szTrans, 256, "%s\n[新·蘑菇世界: 6+2关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_bisounours_party_go_v1", false))
	{
		Format(szTrans, 256, "%s\n[彩虹岛: 4关|BOSS|神器|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_journey_p4", false))
	{
		Format(szTrans, 256, "%s\n[旅程: 1关|神器|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_mountain_escape_v2_2", false))
	{
		Format(szTrans, 256, "%s\n[爬山: 1关|神器|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_slender_escape_csgo_b7", false))
	{
		Format(szTrans, 256, "%s\n[面条人: 6关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_industrial_dejavu_v3_3_3_e2_d", false))
	{
		Format(szTrans, 256, "%s\n[刷分循环: 随机关|神器|BOSS|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_rtcw_ominous_rumors_v1_1", false))
	{
		Format(szTrans, 256, "%s\n[重返德军总部: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_ffxiv_wanderers_palace_v2_2", false))
	{
		Format(szTrans, 256, "%s\n[FF16-流浪者宫殿: 4关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_tloz_stone_tower_temple_v1_4", false))
	{
		Format(szTrans, 256, "%s\n[石塔寺: 3关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_greencity_fix", false))
	{
		Format(szTrans, 256, "%s\n[绿色城市: 5关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_boatescape101_p", false))
	{
		Format(szTrans, 256, "%s\n[逃生船: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_luigismanison_fix2_p3", false))
	{
		Format(szTrans, 256, "%s\n[路易鬼屋: 1关|低奖励 - 中等]", map);
		return true;
	}
	else if(StrEqual(map, "ze_rainbow_factory_v1_2", false))
	{
		Format(szTrans, 256, "%s\n[保护伞公司: 1关|中奖励 - 困难]", map);
		return true;
	}
	else if(StrEqual(map, "ze_panic_escape_v3_2", false))
	{
		Format(szTrans, 256, "%s\n[恐慌逃亡: 1关|低奖励 - 简单]", map);
		return true;
	}
	else if(StrEqual(map, "ze_toaster_p3", false))
	{
		Format(szTrans, 256, "%s\n[面包机: 随机关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_fapescape_rote_v1_1", false))
	{
		Format(szTrans, 256, "%s\n[乐高大城堡: 6关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_Sit_Caelum_Paradisus_b6_2", false))
	{
		Format(szTrans, 256, "%s\n[落在天堂的雕具座: 3关|神器|BOSS|高奖励 - 神图]", map);
		return true;
	}
	else if(StrEqual(map, "ze_vertigo_militia_b1_3_7", false))
	{
		Format(szTrans, 256, "%s\n[眩晕组织: 2关|娱乐|低奖励 - 中等]", map);
		return true;
	}
	


	return false;
}