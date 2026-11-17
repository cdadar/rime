#!/usr/bin/perl
# 检查 Rime 配置/词库里的编码问题：非法 UTF-8、孤立代理项（UTF-16 未配对、按 CESU-8 落盘）、
# U+FFFD、PUA，并统计 Ext A / Ext B+ 生僻字用量（判断字体覆盖需求）。
# 用法: rime_utf8_check.pl <文件或目录>...
# 本文件是仓库内备份副本，可离线直接跑；上游改成两处同步（以另一份为准）。
use strict;
use warnings;
use utf8;
use Encode qw(decode);
use File::Find;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my @files;
for my $arg (@ARGV) {
    if (-d $arg) {
        find({ no_chdir => 1, wanted => sub {
            push @files, $File::Find::name if -f && /\.(?:yaml|txt|org|md|json|tsv)$/;
        } }, $arg);
    } else {
        push @files, $arg;
    }
}

for my $file (sort @files) {
    open my $h, '<:raw', $file or next;
    local $/;
    my $data = <$h>;
    close $h;

    my @problems;

    # 孤立代理项：UTF-16 未配对码元按 CESU-8 落盘的字节形态（合法 UTF-8 不会出现 0xED A0-BF）
    if ($data =~ /(\xED[\xA0-\xBF][\x80-\xBF])/) {
        my $off = $-[1];
        push @problems, sprintf('CESU-8 孤立代理项 @byte %d (%s)', $off, unpack 'H*', $1);
        push @problems, sprintf('  行 %d', 1 + (() = substr($data, 0, $off) =~ /\n/g));
    }

    # 严格解码：抓其它非法序列（FB_CROAK 会吃掉传入的标量，所以传副本）
    eval { decode('UTF-8', my $copy = $data, Encode::FB_CROAK); 1 }
        or push @problems, '非法 UTF-8（严格解码失败）';

    my $text = decode('UTF-8', $data, 0);
    my %count;
    for my $cp (unpack 'U*', $text) {
        $count{pua}++       if $cp >= 0xE000 && $cp <= 0xF8FF;
        $count{fffd}++      if $cp == 0xFFFD;
        $count{surrogate}++ if $cp >= 0xD800 && $cp <= 0xDFFF;
        $count{exta}++      if $cp >= 0x3400 && $cp <= 0x4DBF;
        $count{extb}++      if $cp >= 0x20000;
    }
    my $stat = join ' ', map { "$_=$count{$_}" } grep { $count{$_} } sort keys %count;

    next unless @problems || $stat;
    printf "%-46s %s\n", $file, (@problems ? join('; ', @problems) : $stat);
    printf "%-46s   统计: %s\n", '', $stat if @problems && $stat;
}
