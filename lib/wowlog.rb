#
# Copyright (c) 2014 Masayoshi Mizutani <muret@haeena.net>
# All rights reserved.
#  *
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

require "wowlog/version"
require 'csv'
require 'pp'

module Wowlog

  # Basic class for all column parser
  class ColumnParser 
    def parse_unit_flag(val)
      flag_map = {
        0x00004000 => 'TYPE_OBJECT',
        0x00002000 => 'TYPE_GUARDIAN',
        0x00001000 => 'TYPE_PET',
        0x00000800 => 'TYPE_NPC',
        0x00000400 => 'TYPE_PLAYER',
        0x00000200 => 'CONTROL_NPC',
        0x00000100 => 'CONTROL_PLAYER',
        0x00000040 => 'REACTION_HOSTILE',
        0x00000020 => 'REACTION_NEUTRAL',
        0x00000010 => 'REACTION_FRIENDLY',
        0x00000008 => 'AFFILIATION_OUTSIDER',
        0x00000004 => 'AFFILIATION_RAID',
        0x00000002 => 'AFFILIATION_PARTY',
        0x00000001 => 'AFFILIATION_MINE',
        0x08000000 => 'RAIDTARGET8',
        0x04000000 => 'RAIDTARGET7',
        0x02000000 => 'RAIDTARGET6',
        0x01000000 => 'RAIDTARGET5',
        0x00800000 => 'RAIDTARGET4',
        0x00400000 => 'RAIDTARGET3',
        0x00200000 => 'RAIDTARGET2',
        0x00100000 => 'RAIDTARGET1',
        0x00080000 => 'MAINASSIST',
        0x00040000 => 'MAINTANK',
        0x00020000 => 'FOCUS',
        0x00010000 => 'TARGET',
      }

      res = flag_map.select { |k, v| (val.hex & k) > 0 }
      return res.values
    end

    def parse_school_flag(val)
      school_map = {
        0x1 => 'Physical',
        0x2 => 'Holy',
        0x4 => 'Fire',
        0x8 => 'Nature',
        0x10 => 'Frost',
        0x20 => 'Shadow',
        0x40 => 'Arcane',
      }

      res = school_map.select { |k, v| (val.hex & k) > 0 }
      return res.values
    end

    PT_MAP = {
      -2 => 'health',
      0 => 'mana',
      1 => 'rage',
      2 => 'focus',
      3 => 'energy',
      4 => 'pet happiness',
      5 => 'runes',
      6 => 'runic power'
    }
    def resolv_power_type(pt); return PT_MAP[pt]; end


    def int(v); return v.to_i; end
    def parse(cols, obj = {}); return cols, obj; end
  end

  class EventParser < ColumnParser
    def parse(cols, obj = {})
      obj['event'] = cols.shift
      return cols, obj
    end
  end
  
  class EncountEvent < EventParser
    def parse(cols, obj); end
  end

  class ActionEvent < EventParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['sourceGUID']   = cols.shift
      obj['sourceName']   = cols.shift
      obj['sourceFlags']  = parse_unit_flag(cols.shift)
      obj['sourceFlags2'] = parse_unit_flag(cols.shift)
      obj['destGUID']     = cols.shift
      obj['destName']     = cols.shift
      obj['destFlags']    = parse_unit_flag(cols.shift)
      obj['destFlags2']   = parse_unit_flag(cols.shift)
      return cols, obj
    end
  end

#
# ---------------------------------------------------------
# Prefix Parser Set
# ---------------------------------------------------------
#

  class SpellParser < ActionEvent
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['spellId'] = cols.shift
      obj['spellName'] = cols.shift
      obj['spellSchool'] = parse_school_flag(cols.shift)
      return cols, obj
    end
  end

  class SwingParser < ActionEvent
    def parse(cols, obj); return super(cols, obj); end
  end

  class EnvParser < ActionEvent
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['environmentalType'] = cols.shift
      return cols, obj
    end
  end

#
# ---------------------------------------------------------
# Suffix Parser Set
# ---------------------------------------------------------
#

  class DamageParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      cols.shift(8) # shift 8 columns because unknown parameters

      obj['amount']   = int(cols.shift)
      obj['overkill'] = cols.shift
      obj['school']   = parse_school_flag(cols.shift)
      obj['resisted'] =  int(cols.shift)
      obj['blocked'] =  int(cols.shift)
      obj['absorbed'] =  int(cols.shift)
      obj['critical'] =  (cols.shift != 'nil')
      obj['glancing'] =  (cols.shift != 'nil')
      obj['crushing'] =  (cols.shift != 'nil')
      return cols, obj
    end
  end

  class MissParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['missType'] = cols.shift
      obj['isOffHand'] = cols.shift if cols.size > 0
      obj['amountMissed'] = cols.shift if cols.size > 0
      return cols, obj
    end
  end

  class HealParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      cols.shift(8) # shift 8 columns because unknown parameters

      obj['amount'] = int(cols[0])
      obj['overhealing'] = int(cols[1])
      obj['absorbed'] = int(cols[2])
      obj['critical'] = (cols[3] != 'nil')
      cols.shift(4)
      return cols, obj
    end
  end

  class EnergizeParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      cols.shift(8) # shift 8 columns because unknown parameters

      obj['amount'] = int(cols[0])
      obj['powerType'] = resolv_power_type(cols[1])
      cols.shift(2)
      return cols, obj
    end
  end

  class DrainParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['amount'] = int(cols[0])
      obj['powerType'] = resolv_power_type(cols[1])
      obj['extraAmount'] = int(cols[2])
      cols.shift(3)
      return cols, obj
    end
  end

  class LeechParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['amount'] = int(cols[0])
      obj['powerType'] = resolv_power_type(cols[1])
      obj['extraAmount'] = int(cols[2])
      cols.shift(3)
      return cols, obj
    end
  end

  class SpellBlockParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['extraSpellID'] = cols[0]
      obj['extraSpellName'] = cols[1]
      obj['extraSchool'] = parse_school_flag(cols[2])
      cols.shift(3)

      obj['auraType'] = cols.shift if cols.size > 0
      return cols, obj
    end
  end

  class ExtraAttackParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['amount'] = int(cols.shift)
      return cols, obj
    end
  end

  class AuraParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['auraType'] = cols.shift
      obj['amount'] = int(cols.shift) if cols.size > 0
      obj['auraExtra1'] = cols.shift  if cols.size > 0
      obj['auraExtra2'] = cols.shift  if cols.size > 0
      return cols, obj
    end
  end

  class AuraDoseParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['auraType'] = cols.shift
      obj['powerType'] = resolv_power_type(cols.shift) if cols.size > 0
      return cols, obj
    end
  end

  class AuraBrokenParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['extraSpellID'] = cols.shift
      obj['extraSpellName'] = cols.shift
      obj['extraSchool'] = parse_school_flag(cols.shift)
      obj['auraType'] = cols.shift
      return cols, obj
    end
  end

  class CastFailedParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['failedType'] = cols.shift
      return cols, obj
    end
  end

#
# ---------------------------------------------------------
# Special Event Parser Set
# ---------------------------------------------------------
#

  class EnchantParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['spellName'] = cols[0]
      obj['itemID'] = cols[1]
      obj['itemName'] = cols[2]
      cols.shift(3)
      return cols, obj
    end
  end


  class EncountParser < ColumnParser
    def parse(cols, obj)
      cols, obj = super(cols, obj)
      obj['encounterID'] = cols[0]
      obj['encounterName'] = cols[1]
      obj['difficultyID'] = cols[2]
      obj['groupSize'] = cols[3]
      cols.shift(4)
      
      obj['success'] = (cols.shift == '1') if cols.size > 0
      return cols, obj
    end
  end

  class VoidParser < ColumnParser
    def parse(cols, obj); return super(cols, obj); end
  end

#
# ---------------------------------------------------------
# Main Parser
# ---------------------------------------------------------
#
  class Parser
    def initialize
      @ev_prefix = {
        'SWING' => [SwingParser.new],
        'SPELL_BUILDING' => [SpellParser.new],
        'SPELL_PERIODIC' => [SpellParser.new],
        'SPELL' => [SpellParser.new],
        'RANGE' => [SpellParser.new],
        'ENVIRONMENTAL' => [EnvParser.new],
        'DAMAGE_SHIELD' => [SpellParser.new, DamageParser.new],
        'DAMAGE_SPLIT' => [SpellParser.new, DamageParser.new],
        'DAMAGE_SHIELD_MISSED' => [SpellParser.new, MissParser.new],
        'ENCHANT_APPLIED' => [EnchantParser.new],
        'ENCHANT_REMOVED' => [EnchantParser.new],
        'PARTY_KILL' => [VoidParser.new],
        'UNIT_DIED' => [VoidParser.new],
        'UNIT_DESTROYED' => [VoidParser.new],
        'ENCOUNTER_START' => [EncountParser.new],
        'ENCOUNTER_END' => [EncountParser.new],
      }

      @ev_suffix = {
        '_DAMAGE' => DamageParser.new,
        '_MISSED' => MissParser.new,
        '_HEAL' => HealParser.new,
        '_ENERGIZE' => EnergizeParser.new,
        '_DRAIN' => DrainParser.new,
        '_LEECH' => LeechParser.new,
        '_INTERRUPT' => SpellBlockParser.new,
        '_DISPEL' => SpellBlockParser.new,
        '_DISPEL_FAILED' => SpellBlockParser.new,
        '_STOLEN' => SpellBlockParser.new,
        '_EXTRA_ATTACKS' => ExtraAttackParser.new,
        '_AURA_APPLIED' => AuraParser.new,
        '_AURA_REMOVED' => AuraParser.new,
        '_AURA_APPLIED_DOSE' => AuraDoseParser.new,
        '_AURA_REMOVED_DOSE' => AuraDoseParser.new,
        '_AURA_REFRESH' => AuraDoseParser.new,
        '_AURA_BROKEN' => AuraParser.new,
        '_AURA_BROKEN_SPELL' => AuraBrokenParser.new,
        '_CAST_START' => nil,
        '_CAST_SUCCESS' => nil,
        '_CAST_FAILED' => CastFailedParser.new,
        '_INSTAKILL' => nil,
        '_DURABILITY_DAMAGE' => nil,
        '_DURABILITY_DAMAGE_ALL' => nil,
        '_CREATE' => nil,
        '_SUMMON' => nil,
        '_RESURRECT' => nil,
      }
    end

    def parse_cols(cols)
      orig_txt = cols.join(',')
      ev_orig = cols[0]
      event = cols[0]

      psr_seq = []
      p_psr = @ev_prefix.inject(['', nil]) { |m, (k, v)| 
        (event.start_with?(k) and m[0].size < k.size) ? [k, v] : m
      }
      psr_seq += p_psr[1]

      event = event[(p_psr[0].size)..-1]
      s_psr = @ev_suffix.inject(['', nil]) { |m, (k, v)| 
        (event.start_with?(k) and m[0].size < k.size) ? [k, v] : m
      }
      psr_seq << s_psr[1] unless s_psr[1].nil?

      obj = {}
      psr_seq.each do |psr|
        cols, obj = psr.parse(cols, obj)
      end

      if cols.size > 0 and ev_orig != 'SPELL_CAST_SUCCESS'
        puts
        p psr_seq
        puts orig_txt
        p cols
        pp obj
      end
    end

    def parse_line(line)
      terms = line.split(' ')
      raise "Invalid format, '#{line.strip}'" if terms.size < 3

      # Parse timestamp and adjust error of milli second
      datetime = terms[0..1].join(' ')
      ms = datetime.scan(/\.(\d+)$/)[0][0]
      parsed_ts = Time.parse(datetime)
      ts = parsed_ts.to_i.to_f + (ms.to_f / 1000)

      # rebuild CSV part
      csv_txt = terms[2..-1].join(' ')
      cols = CSV.parse(csv_txt)[0]

      # parse CSV part
      obj = parse_cols(cols)
    end
  end
end
