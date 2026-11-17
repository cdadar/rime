#!/usr/bin/perl
# 统计字体文件对 CJK 汉字段落（URO / Ext A–H / 兼容区）的覆盖情况。
# 依赖 fontconfig 的 fc-query（macOS: brew install fontconfig）。
# 用法: font_coverage.pl 字体文件...
# 本文件是仓库内备份副本，可离线直接跑；上游改成两处同步（以另一份为准）。
use strict;
use warnings;
use utf8;
use Encode qw(decode);

binmode STDOUT, ':utf8';

my @blocks = (
    [ 'URO',   0x4E00,  0x9FFF,  20992 ],
    [ 'ExtA',  0x3400,  0x4DBF,  6592 ],
    [ 'ExtB',  0x20000, 0x2A6DF, 42720 ],
    [ 'ExtC',  0x2A700, 0x2B73F, 4154 ],
    [ 'ExtD',  0x2B740, 0x2B81F, 222 ],
    [ 'ExtE',  0x2B820, 0x2CEAF, 5762 ],
    [ 'ExtF',  0x2CEB0, 0x2EBEF, 7473 ],
    [ 'ExtG',  0x30000, 0x3134F, 4939 ],
    [ 'ExtH',  0x31350, 0x323AF, 4192 ],
    [ '兼容区', 0xF900, 0xFAFF, 512 ],
);

for my $file (@ARGV) {
    unless (-f $file) { warn "没有这个文件: $file\n"; next }
    my $info = `fc-query --format '%{family}|%{postscriptname}\\n' "$file" 2>/dev/null`;
    $info = decode('UTF-8', $info);  # fc-query 直接吐 UTF-8 字节，不解码会双编码乱码
    chomp $info;
    my $charset = `fc-query --format '%{charset}\\n' "$file" 2>/dev/null`;
    chomp $charset;
    unless ($charset) { warn "fc-query 读不出 charset: $file\n"; next }

    # charset 形如 "20-7e a0-ff 4e00-9fff ..."
    my @ranges;
    for my $r (split /\s+/, $charset) {
        my ($a, $b) = split /-/, $r;
        $b = $a if !defined $b;
        push @ranges, [ hex($a), hex($b) ];
    }

    my @out;
    my $total = 0;
    for my $blk (@blocks) {
        my ($name, $lo, $hi, $cap) = @$blk;
        my $n = 0;
        for my $rg (@ranges) {
            my $s = $rg->[0] > $lo ? $rg->[0] : $lo;
            my $e = $rg->[1] < $hi ? $rg->[1] : $hi;
            $n += $e - $s + 1 if $e >= $s;
        }
        $total += $n;
        push @out, sprintf('%s %d/%d(%.1f%%)', $name, $n, $cap, 100 * $n / $cap) if $n;
    }
    printf "%-56s %s\n  %s\n", $file, $info, join ' ', @out;
}
