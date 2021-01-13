/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * Authors:
 *  Arthur Mello <arthur.mello@canonical.com>
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "fileoperations.h"

#include <QDir>
#include <QFile>
#include <QTemporaryFile>
#include <QStandardPaths>
#include <QDebug>

FileOperations::FileOperations(QObject *parent)
    : QObject(parent)
{
}

FileOperations::~FileOperations()
{
}

QString FileOperations::getTemporaryFile(const QString &fileExtension) const
{
    //TODO remove once lp:1420728 is fixed
    QDir dataLocation(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    if (!dataLocation.exists()) {
        dataLocation.mkpath(".");
    }
    QTemporaryFile tmp(dataLocation.path() + "/tmpXXXXXX" + fileExtension);
    tmp.open();
    return tmp.fileName();
}

bool FileOperations::link(const QString &from, const QString &to)
{
    return QFile::link(from, to);
}

bool FileOperations::remove(const QString &fileName)
{
    return QFile::remove(fileName);
}

qint64 FileOperations::size(const QString &filePath)
{
    return QFile(filePath).size();
}

bool FileOperations::create(const QString &dirPath)
{

    QDir newDir(dirPath);
    if (!newDir.exists()) {
        qDebug() << "created new sticker dir:" << dirPath;
        return newDir.mkpath(dirPath);
    }
    return false;
}

bool FileOperations::removeDir(const QString &dirPath)
{

    QDir dir(dirPath);
    if (dir.exists()) {
        qDebug() << "removed sticker pack:" << dirPath;
        return dir.removeRecursively();
    }
    return false;
}


bool FileOperations::copyFile(const QString &from, const QString &to) {
    if(QFile::exists(to)) QFile::remove(to);
    qDebug() << "copied file from " << from << " to " << to;
    return QFile::copy(from, to);
}

